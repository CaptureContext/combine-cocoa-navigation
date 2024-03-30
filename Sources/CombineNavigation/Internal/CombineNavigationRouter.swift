#if canImport(UIKit) && !os(watchOS)
import Capture
import CocoaAliases
import Combine
import FoundationExtensionsMacros
import CombineCocoa
import ConcurrencyExtras
import CombineInterceptionMacros

extension CocoaViewController {
	@_spi(Internals)
	public var combineNavigationRouter: CombineNavigationRouter {
		getAssociatedObject(forKey: #function) ?? {
			let router = CombineNavigationRouter(self)
			setAssociatedObject(router, forKey: #function)
			return router
		}()
	}

	public func registerRoutedChild(_ controller: CocoaViewController) {
		combineNavigationRouter.addChild(controller.combineNavigationRouter)
	}

	public func unregisterRoutedChild(_ controller: CocoaViewController) {
		combineNavigationRouter.removeChild(controller.combineNavigationRouter)
	}
}

extension CombineNavigationRouter {
	@_spi(Internals)
	public class NavigationRoute: Identifiable {
		public let id: AnyHashable

		public let routingControllerID: ObjectIdentifier
		private(set) public var routedControllerID: ObjectIdentifier?

		private let controller: () -> CocoaViewController?
		let invalidationHandler: (() -> Void)?

		public init(
			id: AnyHashable,
			routingControllerID: ObjectIdentifier,
			controller: @escaping () -> CocoaViewController?,
			invalidationHandler: (() -> Void)?
		) {
			self.id = id
			self.routingControllerID = routingControllerID
			self.controller = controller
			self.invalidationHandler = invalidationHandler
		}

		public func makeController(
			routedBy parentRouter: CombineNavigationRouter
		) -> CocoaViewController? {
			let controller = self.controller()
			controller.map { parentRouter.addChild($0.combineNavigationRouter) }
			routedControllerID = controller?.objectID
			return controller
		}
	}
}

extension CombineNavigationRouter {
	@inlinable
	public func addChild(_ router: CombineNavigationRouter) {
		self.removeChild(router)
		router.parent = self
		children.append(.init(router))
	}

	@inlinable
	@discardableResult
	public func removeChild(_ router: CombineNavigationRouter) -> Bool {
		var isRemoved: Bool = false
		children.removeAll {
			let remove = $0.object === router
			isRemoved = isRemoved || remove
			return remove
		}
		if isRemoved { router.parent = nil }
		return isRemoved
	}

	@inlinable
	public func removeFromParent() {
		guard let parent else { return }
		parent.removeChild(self)
	}
}

@_spi(Internals)
public final class CombineNavigationRouter: Weakifiable {
	public func resetPresentation() {
		present(nil, onDismiss: {})
	}

	public func resetNavigationRoutes() {
		let allRoutes = collectManagedRoutes()
		guard allRoutes.isNotEmpty else { return }

		withNavigationTransaction {
			self.setRoutes([], onPop: nil)
			children.forEach {
				$0.object?.beginNavigationTransaction()
				$0.object?.resetNavigationRoutes()
			}
		}

		node?.navigationController.map(syncNavigationStack)

		children.forEach { $0.object?.endNavigationTransaction() }
	}

	struct NavigationTransaction {
		var count: Int = 0
	}

	private var navigationTransaction: NavigationTransaction?

	func beginNavigationTransaction() {
		if navigationTransaction.isNil {
			self.navigationTransaction = .init()
		} else {
			self.navigationTransaction?.count += 1
		}
	}

	func endNavigationTransaction() {
		if navigationTransaction?.count == 0 {
			self.navigationTransaction = nil
		} else {
			self.navigationTransaction?.count -= 1
		}
	}

	func withNavigationTransaction(perform operation: () -> Void) {
		beginNavigationTransaction()
		operation()
		endNavigationTransaction()
	}

	public weak var parent: CombineNavigationRouter?

	public weak var node: CocoaViewController!

	public var children: [Weak<CombineNavigationRouter>] = [] {
		didSet { children.removeAll(where: \.object.isNil) }
	}

	fileprivate var isDirectChild: Bool {
		guard
			let parent,
			let parentNode = parent.node
		else { return false }
		return parent.children
			.compactMap(\.object?.objectID)
			.contains(objectID)
		&& node.view.isNestedSubview(of: parentNode.view)
	}

	fileprivate func navigationGroupRoot() -> CombineNavigationRouter {
		if isDirectChild { return parent?.navigationGroupRoot() ?? self }
		else { return self }
	}

	fileprivate var navigationControllerCancellable: Cancellable?
	fileprivate var navigationControllerPublisher: some Publisher<UINavigationController, Never> {
		navigationControllerSubject.compactMap(\.object)
	}
	fileprivate var navigationControllerSubject = CurrentValueSubject<
		Weak<UINavigationController>,
		Never
	>(.init())

	fileprivate var navigationStackSyncCancellable: AnyCancellable?
	fileprivate var windowCancellable: AnyCancellable?

	fileprivate var destinationDismissCancellable: AnyCancellable?
	fileprivate var destinationPopCancellable: AnyCancellable?

	fileprivate var popHandler: (([NavigationRoute]) -> Void)?
	fileprivate var routes: [NavigationRoute] = []
	fileprivate var presentedDestination: _PresentationDestinationProtocol?

	fileprivate init(_ node: CocoaViewController?) {
		self.node = node
		self.subscribeToNavigationController()
	}

	public func setRoutes(
		_ routes: [NavigationRoute],
		onPop: (([NavigationRoute]) -> Void)?
	) {
		self.routes = routes
		self.popHandler = { [weak self] routes in
			if self?.navigationTransaction == nil {
				onPop?(routes)
			}
		}
		self.requestNavigationStackSync()
	}

	public func present(
		_ presentationDestination: _PresentationDestinationProtocol?,
		onDismiss: @escaping () -> Void
	) {
		self.requestSetPresentationDestination(
			presentationDestination,
			onDismiss: { [weak self] in
				if self?.navigationTransaction == nil {
					onDismiss()
			 }
		 }
		)
	}

	public func makeNavigationRoute<ID: Hashable>(
		for id: ID,
		controller: @escaping () -> CocoaViewController?,
		invalidationHandler: (() -> Void)? = nil
	) -> NavigationRoute {
		NavigationRoute(
			id: id,
			routingControllerID: node.objectID,
			controller: controller,
			invalidationHandler: invalidationHandler
		)
	}
}

// MARK: Navigation stack sync

extension CombineNavigationRouter {
	fileprivate func requestSetPresentationDestination(
		_ destination: _PresentationDestinationProtocol?,
		onDismiss: @escaping () -> Void
	) {
		guard let node else { return }

		node.view.publishers.isReadyForPresenting
			.compactMap { $0 ? () : nil }
			.sink(receiveValue: capture { _self in
				_self._setPresentationDestination(
					destination,
					onDismiss: onDismiss
				)
			})
			.store(in: &windowCancellable)
	}

	private func _setPresentationDestination(
		_ newDestination: _PresentationDestinationProtocol?,
		onDismiss: @escaping () -> Void
	) {
		self.windowCancellable = nil

		let router = self.navigationGroupRoot()
		let oldDestination = router.presentedDestination

		guard oldDestination !== newDestination else { return }

		router.destinationDismissCancellable = nil

		let __presentNewDestinationIfNeeded: () -> Void = { [weak self] in
			oldDestination?._invalidate()
			router.presentedDestination = newDestination

			guard self?.navigationTransaction == nil else { return }
			self?.presentCurrentDestination(onDismiss: onDismiss)
		}

		if router.node.presentedViewController != nil {
			// Cancel current dismiss subscription
			// to avoid dismiss action called on
			// state changes
			router.destinationDismissCancellable = nil
			router.presentedDestination = nil
			router.node.dismiss(completion: __presentNewDestinationIfNeeded)
		} else {
			__presentNewDestinationIfNeeded()
		}
	}

	private func presentCurrentDestination(onDismiss: @escaping () -> Void) {
		let router = self.navigationGroupRoot()
		guard let destination = router.presentedDestination else { return }

		let controller = destination._initControllerForPresentationIfNeeded()

		controller.publishers._testableDismissed
			.sink(receiveValue: onDismiss)
			.store(in: &router.destinationDismissCancellable)

		router.node.present(controller)
	}

	private func subscribeToNavigationController() {
		navigationControllerCancellable = node?
			.publisher(for: \.navigationController)
			.map(capture { _self, navigation in
				navigation.map(_self.subscribeToPop(from:))
				return navigation
			})
			.map(Weak.init(_:))
			.resend(to: navigationControllerSubject)
	}

	private func subscribeToPop(from navigation: UINavigationController) {
		navigation.publishers.didPopControllers
			.sink(receiveValue: capture { _self, controllers in
				let routes = _self.routes.reduce(into: (
					kept: [NavigationRoute](),
					popped: [NavigationRoute]()
				)) { routes, route in
					if controllers.contains(where: { $0.objectID == route.routedControllerID }) {
						routes.popped.append(route)
					} else {
						routes.kept.append(route)
					}
				}
				_self.routes = routes.kept
				_self.popHandler?(routes.popped)
			})
			.store(in: &destinationPopCancellable)
	}

	public func requestNavigationStackSync() {
		navigationControllerPublisher
			.sinkValues(capture { $0.syncNavigationStack(using: $1) })
			.store(in: &navigationStackSyncCancellable)
	}

	private func syncNavigationStack(
		using navigation: UINavigationController
	) {
		navigationStackSyncCancellable = nil

		if navigationTransaction == nil {
			let controllers = buildNavigationStack()
			navigation.setViewControllers(controllers)
		}
	}
}

// MARK: Build navigation stack

extension CombineNavigationRouter {
	public func buildNavigationStack() -> [CocoaViewController] {
		parent
			.map { $0.buildNavigationStack() }
			.or(
				[node].compactMap { $0 } +
				self.buildManagedNavigationStack()
			)
	}

	public func buildManagedNavigationStack() -> [CocoaViewController] {
		prepareRoutedControllers().flatMap { controller in
			[controller] + controller.combineNavigationRouter.buildManagedNavigationStack()
		}
	}

	public func prepareRoutedControllers() -> [CocoaViewController] {
		return processManagedRoutes { $1.makeController(routedBy: $0) }
	}

	public func collectManagedRoutes() -> [NavigationRoute] {
		return processManagedRoutes { _, route in route }
	}

	private func processManagedRoutes<Object>(_ f: (CombineNavigationRouter, NavigationRoute) -> Object?) -> [Object] {
		return children.compactMap(\.object).filter(\.isDirectChild).flatMap { $0.processManagedRoutes(f) }
		+ routes.compactMap { f(self, $0) } // indirect children are equal to routes
	}

	public func printRoutersGraph(childIndex: Int? = nil, _ nesting: Int = 0, to target: inout some TextOutputStream) {
		var indent = String(repeating: "  ", count: nesting) + "-"

		if let childIndex { indent += " \(childIndex):" }

		print(indent, String(describing: type(of: node!)), node.objectID, isDirectChild, to: &target)
		children.enumerated().forEach { index, child in
			child.object?.printRoutersGraph(childIndex: index, nesting + 1, to: &target)
		}
	}
}

extension CocoaView {
	func isNestedSubview(of parent: CocoaView) -> Bool {
		superview === parent || superview?.isNestedSubview(of: parent) == true
	}
}

extension UIResponder {
	var __window: UIWindow? {
		guard let window = self as? UIWindow 
		else { return next?.__window }
		return window
	}
}

extension PublishersProxy where Base: CocoaViewController {
	var _testableDismissed: some Publisher<Void, Never> {
		#if canImport(XCTest)
		if let controller = base.as(AppleSpaghettiCodeTestableController.self) {
			return controller.publisher(
				for: #selector(AppleSpaghettiCodeTestableController.wasDismissed)
			).eraseToAnyPublisher()
		} else {
			return dismissed.eraseToAnyPublisher()
		}
		#else
		return dismissed
		#endif
	}
}

extension PublishersProxy where Base: CocoaView {
	var isReadyForPresenting: some Publisher<Bool, Never> {
		#if canImport(XCTest)
		return Just(true)
		#else
		return Publishers.Merge(
			Just(base.window.isNotNil),
			base.publisher(for: #methodSelector(UIView.didMoveToWindow))
				.replaceOutput(with: ())
				.compactMap { [weak base] in base?.window.isNotNil }
		)
		#endif
	}
}

#endif

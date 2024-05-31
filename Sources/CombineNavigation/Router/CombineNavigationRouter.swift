#if canImport(UIKit) && !os(watchOS)
import Capture
import CocoaAliases
import Combine
import FoundationExtensionsMacros
import CombineCocoa
import ConcurrencyExtras
import CombineInterceptionMacros

@_spi(Internals)
public final class CombineNavigationRouter: Weakifiable {

	internal init(_ node: CocoaViewController?) {
		self.node = node
		self.subscribeToNavigationController()
	}

	// MARK: Stored

	@usableFromInline
	@Reference
	var navigationPathStorage: NavigationPathStorage = .init()

	fileprivate var navigationControllerSubject = CurrentValueSubject<
		UINavigationController?,
		Never
	>(nil)

	fileprivate var navigationControllerPublisher: some Publisher<UINavigationController, Never> {
		return navigationControllerSubject
			.compactMap { $0 }
			.removeDuplicates(by: ===)
	}

	/// Subscriptions
	fileprivate var cancellables: Cancellables = .init()

	/// Parent router
	public weak var parent: CombineNavigationRouter?

	/// Associated viewController
	public weak var node: CocoaViewController!

	/// Direct routes set up by navigationStack/navigationDestination API methods
	fileprivate var routes: [NavigationRoute] = []

	/// Only one destination can be presented
	fileprivate var presentedDestination: _PresentationDestinationProtocol?

	/// Handler that recieves an array of popped routes
	///
	/// each popped route is taken from the `.routes` property
	fileprivate var popHandler: (([NavigationRoute]) -> Void)?

	// MARK: Computed

	@PropertyProxy(\CombineNavigationRouter.navigationPathStorage.navigationTransaction)
	fileprivate var navigationTransaction: NavigationTransaction?

	public var children: [Weak<CombineNavigationRouter>] = [] {
		didSet { children.removeAll(where: \.object.isNil) }
	}

	var isDerivedDestination: Bool = false

	/// Used for presentation, find root router in view hierarchy
	///
	/// > This method doesn't search for the root router, the search is based on view hierarchy
	fileprivate func navigationGroupRoot() -> CombineNavigationRouter {
		if isDerivedDestination { return parent?.navigationGroupRoot() ?? self }
		else { return self }
	}

	// MARK: Navigation Controller

	/// Subscribes on navigationController property of the node
	private func subscribeToNavigationController() {
		cancellables.navigationController = node.map { node in
			node.publishers.navigationController
				.sinkValues(capture { _self, navigation in
					_self.navigationControllerSubject.send(navigation)
				})
		}
		subscribeToPop()
	}

	// MARK: Main internal APIs
	// Subscription APIs are declared in Router+API.swift

	public func setRoutes(
		_ routes: [NavigationRoute],
		onPop: (([NavigationRoute]) -> Void)?
	) {
		print(node?.objectID as Any, #function)

		func derivedDestinationsRoutes() -> [NavigationRoute] {
			(node as? any RoutingController)?.__tryGetDerivedDestinations().map {
				makeNavigationRoute(
					for: UUID(),
					controller: $0._initControllerIfNeeded,
					invalidationHandler: $0._invalidate
				)
			} ?? []
		}

		withNavigationTransaction { transaction in
			self.routes = routes
			self.popHandler = { routes in
				onPop?(routes)
			}

			// Instantiate child controllers for current routes
			// they will be held by their destination wrappers
			// for sync after the whole navigationStack is built

			// TODO: Use navigationControllerSubject and set it's value here
			// to avoid resync when nav is set
			
			(derivedDestinationsRoutes() + routes).forEach { $0.makeController(routedBy: self) }

			if transaction.isRoot {
				transaction.setNavigationCompletion { [weak self] in
					print(self?.node?.objectID as Any, "transaction completion", self?.parent.isNil as Any)
					self?.requestNavigationStackSync()
				}
			}
		}
	}

	public func present(
		_ presentationDestination: _PresentationDestinationProtocol?,
		onDismiss: @escaping () -> Void
	) {
		self.requestSetPresentationDestination(
			presentationDestination,
			onDismiss: onDismiss
		)
	}

	public func makeNavigationRoute<ID: Hashable>(
		for id: ID,
		controller: @escaping ((CocoaViewController) -> Void) -> CocoaViewController?,
		invalidationHandler: (() -> Void)? = nil
	) -> NavigationRoute {
		NavigationRoute(
			id: id,
			routingControllerID: node.objectID,
			controller: controller,
			invalidationHandler: invalidationHandler
		)
	}

	// MARK: - Children

	public func addChild(_ router: CombineNavigationRouter) {
		self.removeChild(router)
		router._navigationPathStorage = _navigationPathStorage
		router.parent = self
		children.append(.init(router))
	}

	@discardableResult
	public func removeChild(_ router: CombineNavigationRouter) -> Bool {
		var isRemoved: Bool = false
		children.removeAll {
			let remove = $0.object === router
			isRemoved = isRemoved || remove
			return remove
		}
		if isRemoved {
			router.parent = nil
			router._navigationPathStorage = .variable(.init())
		}
		return isRemoved
	}

	@inlinable
	public func removeFromParent() {
		guard let parent else { return }
		parent.removeChild(self)
	}
}

// MARK: Navigation stack sync

extension CombineNavigationRouter {
	fileprivate func requestSetPresentationDestination(
		_ destination: _PresentationDestinationProtocol?,
		onDismiss: @escaping () -> Void
	) {
		guard let node else { return }

		node.view.publishers._testableIsReadyForPresenting
			.compactMap { $0 ? () : nil }
			.sink(receiveValue: capture { _self in
				_self._setPresentationDestination(
					destination,
					onDismiss: onDismiss
				)
			})
			.store(in: &cancellables.isReadyForPresenting)
	}

	private func _setPresentationDestination(
		_ newDestination: _PresentationDestinationProtocol?,
		onDismiss: @escaping () -> Void
	) {
		self.cancellables.isReadyForPresenting = nil

		let router = self.navigationGroupRoot()
		let oldDestination = router.presentedDestination

		guard oldDestination !== newDestination else { return }

		router.cancellables.presentationDestinationDismiss = nil

		let __presentNewDestinationIfNeeded: () -> Void = { [weak self] in
			oldDestination?._invalidate()
			router.presentedDestination = newDestination

			// TODO: Refactor navigationTransaction usage
			// maybe create navigationStack-like presentationStack
			// the point is to be able to sync UI with the whole navigation&presentation state of the app
			// in one completion action
			guard self?.navigationTransaction == nil else { return }
			self?.presentCurrentDestination(onDismiss: onDismiss)
		}

		if router.node.presentedViewController != nil {
			// Cancel current dismiss subscription
			// to avoid dismiss action called on
			// state changes
			router.cancellables.presentationDestinationDismiss = nil
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
			.store(in: &router.cancellables.presentationDestinationDismiss)

		router.node.present(controller)
	}

	private func subscribeToPop() {
		navigationControllerPublisher
			.map { [weak self] navigation in
				print(self?.node?.objectID as Any, #function, navigation.objectID)
				return navigation
			}
			.flatMap(\.publishers.didPopControllers)
			.sink(receiveValue: capture { _self, controllers in
				print(_self.node?.objectID as Any, "didHandlePop", controllers.map(\.objectID), "when_managed", _self.routes.map(\.routedControllerID))
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
				if let node = _self.node, controllers.contains(node) {
					_self.cancellables.cancel()
				}
			})
			.store(in: &cancellables.navigationDestinationPop)
	}

	public func requestNavigationStackSync() {
		print(node?.objectID as Any, #function, node?.navigationController.isNil as Any)
		if let navigation = navigationGroupRoot().node?.navigationController {
			syncNavigationStack(using: navigation)
		} else {
			navigationControllerPublisher
				.sinkValues(capture { $0.syncNavigationStack(using: $1) })
				.store(in: &cancellables.navigationStackSync)
		}
	}

	private func syncNavigationStack(
		using navigation: UINavigationController
	) {
		cancellables.navigationStackSync = nil

		print(node?.objectID as Any, #function)
		let navigationStack = buildNavigationStack()
		navigation.setViewControllers(navigationStack)
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
		return children.compactMap(\.object).filter(\.isDerivedDestination).flatMap { $0.processManagedRoutes(f) }
		+ routes.compactMap { f(self, $0) } // indirect children are equal to routes
	}

	public func printRoutersGraph(childIndex: Int? = nil, _ nesting: Int = 0, to target: inout some TextOutputStream) {
		var indent = String(repeating: "  ", count: nesting) + "-"

		if let childIndex { indent += " \(childIndex):" }

		print(indent, String(describing: type(of: node!)), node.objectID, isDerivedDestination, to: &target)
		children.enumerated().forEach { index, child in
			child.object?.printRoutersGraph(childIndex: index, nesting + 1, to: &target)
		}
	}
}

// MARK: - Cancellables

extension CombineNavigationRouter {
	struct Cancellables: Cancellable {
		var isReadyForPresenting: AnyCancellable?

		var navigationController: AnyCancellable?
		var navigationStackSync: AnyCancellable?

		var presentationDestinationDismiss: AnyCancellable?
		var navigationDestinationPop: AnyCancellable?

		func cancel() {
			isReadyForPresenting?.cancel()
			navigationController?.cancel()
			navigationStackSync?.cancel()
			presentationDestinationDismiss?.cancel()
			navigationDestinationPop?.cancel()
		}
	}
}

// MARK: - NavigationTransaction

extension CombineNavigationRouter {
	struct NavigationTransaction {
		var nesting: Int = 0
		var navigationCompletion: (() -> Void)? = nil
		var presentaitonCompletion: (() -> Void)? = nil

		func triggerCompletions() {
			navigationCompletion?()
			presentaitonCompletion?()
		}

		struct Proxy {
			var isRoot: Bool { nesting == 0 }
			let nesting: Int
			let setNavigationCompletion: (@escaping () -> Void) -> Void
			let setPresentationCompletion: (@escaping () -> Void) -> Void
		}
	}

	func withNavigationTransaction(
		perform operation: (NavigationTransaction.Proxy) -> Void
	) {
		beginNavigationTransaction()
		operation(.init(
			nesting: navigationTransaction?.nesting ?? 0,
			setNavigationCompletion: { [weak self] completion in
				self?.navigationTransaction?.navigationCompletion = completion
			},
			setPresentationCompletion: { [weak self] completion in
				self?.navigationTransaction?.presentaitonCompletion = completion
			}
		))
		endNavigationTransaction()
	}

	func beginNavigationTransaction() {
		if navigationTransaction.isNil {
			print(node?.objectID as Any, #function, navigationTransaction?.nesting ?? "none -> 0")
			self.navigationTransaction = .init()
		} else {
			print(
				node?.objectID as Any,
				#function,
				navigationTransaction.map { "\($0.nesting) -> \($0.nesting + 1)" } ?? "none"
			)
			self.navigationTransaction?.nesting += 1
		}
	}

	func endNavigationTransaction() {
		if navigationTransaction?.nesting == 0 {
			print(node?.objectID as Any, #function, navigationTransaction?.nesting ?? "0 -> none")
			self.navigationTransaction?.triggerCompletions()
			self.navigationTransaction = nil
		} else {
			print(
				node?.objectID as Any,
				#function,
				navigationTransaction.map { "\($0.nesting) -> \($0.nesting - 1)" } ?? "none"
			)
			self.navigationTransaction?.nesting -= 1
		}
	}
}

// MARK: - Reset

extension CombineNavigationRouter {
	@usableFromInline
	struct NavigationPathStorage {
		/// Disables sync with navController and handlers during state updates when atomic updates are needed
		var navigationTransaction: NavigationTransaction? = nil
	}

	public func resetPresentation() {
		present(nil, onDismiss: {})
	}

	public func resetNavigationRoutes() {
		let allRoutes = collectManagedRoutes()
		guard allRoutes.isNotEmpty else { return }

		withNavigationTransaction { _ in
			self.setRoutes([], onPop: nil)
			children.forEach {
				$0.object?.resetNavigationRoutes()
			}
		}
	}
}

extension RoutingController {
	func __tryGetDerivedDestinations() -> [_DerivedDestinationProtocol] {
		_makeDerivedDestinations().allDestinations
	}
}

// - MARK: PLAYGROUND

indirect enum NavigationStateNode {
	var id: UUID {
		switch self {
		case let .tree(node): return node.id
		case let .stack(node): return node.id
		}
	}

	case tree(Tree = .init())
	case stack(Stack = .init())

	struct Tree {
		var id: UUID = .init()
		var managed: NavigationStateNode?
		var presented: NavigationStateNode?
	}

	struct Stack {
		var id: UUID = .init()
		var managed: [NavigationStateNode] = []
		var presented: NavigationStateNode?
	}

	func print(
		indentor: String = " ",
		indentWidth: Int = 2,
		indentation: Int = 0,
		presentedBy presenter: UUID? = nil
	) {
		let indent = String(repeating: indentor, count: indentation * indentWidth)
		Swift.print(indent + id.uuidString.lowercased() + (presenter.map { _ in " (p)" } ?? ""))

		switch self {
		case let .tree(node):
			node.presented.map { presented in
				presented.print(
					indentation: indentation + 1,
					presentedBy: node.id
				)
			}
			node.managed.map { managed in
				managed.print(indentation: indentation + 1)
			}
		case let .stack(node):
			node.presented.map { presented in
				presented.print(
					indentation: indentation + 1,
					presentedBy: node.id
				)
			}
			node.managed.forEach { managed in
				managed.print(indentation: indentation + 1)
			}
		}
	}

	/// Example
	///
	/// NavStack:
	/// ```
	/// [stack1, stack1.tree1, stack1.tree2, stack1.tree2.tree1, stack1.tree3, stack1.stack1, stack1.stack1.stack1, stack1.tree4] (8)
	/// ```
	///
	/// PresStack:
	/// ```
	/// [stack1.tree3.p(stack), stack1.tree3.p(stack).tree1.p(stack)] (2)
	/// ```
	static let example: NavigationStateNode = {
		.stack([
			.tree(),
			.tree(.init(
				managed: .tree()
			)),
			.tree(.init(
				presented: .stack([
					.tree(.init(
						presented: .stack([])
					))
				])
			)),
			.stack([
				.stack([])
			]),
			.tree()
		])
	}()
}



func collectNavigationStack(from root: NavigationStateNode) -> [UUID] {
	switch root {
	case let .tree(node):
		return [node.id] + (node.managed.map(collectNavigationStack) ?? [])
	case let .stack(node):
		return [node.id] + node.managed.flatMap(collectNavigationStack)
	}
}

func collectPresentationStack(from root: NavigationStateNode) -> [UUID] {
	switch root {
	case let .tree(node):
		let presentedStack = node.presented.map { presented in
			return [presented.id] + collectPresentationStack(from: presented)
		} ?? []

		return presentedStack + (node.managed.map(collectPresentationStack) ?? [])

	case let .stack(node):
		let presentedStack = node.presented.map { presented in
			return [presented.id] + collectPresentationStack(from: presented)
		} ?? []

		return presentedStack + node.managed.flatMap(collectPresentationStack)
	}
}

extension NavigationStateNode.Stack: ExpressibleByArrayLiteral {
	init(arrayLiteral elements: NavigationStateNode...) {
		self.init(managed: elements)
	}
}
#endif

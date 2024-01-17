#if canImport(UIKit) && !os(watchOS)
import Capture
import CocoaAliases
import Combine
import FoundationExtensions

extension CocoaViewController {
	@usableFromInline
	internal var combineNavigationRouter: CombineNavigationRouter {
		getAssociatedObject(forKey: #function) ?? {
			let router = CombineNavigationRouter(self)
			setAssociatedObject(router, forKey: #function)
			return router
		}()
	}

	@inlinable
	public func addRoutedChild(_ controller: CocoaViewController) {
		combineNavigationRouter.addChild(controller.combineNavigationRouter)
		addChild(controller)
	}
}

extension CombineNavigationRouter {
	@usableFromInline
	class NavigationRoute: Identifiable {
		@usableFromInline
		let id: AnyHashable

		let routingControllerID: ObjectIdentifier
		private(set) var routedControllerID: ObjectIdentifier?
		private let controller: () -> CocoaViewController?
		let invalidationHandler: (() -> Void)?

		init(
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

		func makeController(
			routedBy parentRouter: CombineNavigationRouter
		) -> CocoaViewController? {
			let controller = self.controller()
			controller?.combineNavigationRouter.parent = parentRouter
			routedControllerID = controller?.objectID
			return controller
		}
	}
}

@usableFromInline
final class CombineNavigationRouter: Weakifiable {
	fileprivate weak var parent: CombineNavigationRouter?
	fileprivate weak var node: CocoaViewController!

	fileprivate var directChildren: [Weak<CombineNavigationRouter>] = [] {
		didSet { directChildren.removeAll(where: \.object.isNil) }
	}

	fileprivate var isDirectChild: Bool {
		true == parent?.directChildren
			.compactMap(\.object?.objectID)
			.contains(objectID)
	}

	fileprivate func navigationGroupRoot() -> CombineNavigationRouter {
		return isDirectChild
		? parent!.navigationGroupRoot()
		: self
	}

	fileprivate var navigationControllerCancellable: AnyCancellable?
	fileprivate var windowCancellable: AnyCancellable?

	fileprivate var destinationDismissCancellable: AnyCancellable?
	fileprivate var destinationPopCancellable: AnyCancellable?

	fileprivate var popHandler: (([NavigationRoute]) -> Void)?
	fileprivate var routes: [NavigationRoute] = []
	fileprivate var presentedDestination: _PresentationDestinationProtocol?

	fileprivate init(_ node: CocoaViewController?) {
		self.node = node
	}

	@usableFromInline
	internal func addChild(_ router: CombineNavigationRouter) {
		router.parent = self
		directChildren.removeAll(where: { $0.object === router })
		directChildren.append(.init(router))
	}

	func setRoutes(
		_ routes: [NavigationRoute],
		onPop: (([NavigationRoute]) -> Void)?
	) {
		self.routes = routes
		self.popHandler = onPop
		self.requestNavigationStackSync()
	}

	func present(
		_ presentationDestination: _PresentationDestinationProtocol?,
		onDismiss: @escaping () -> Void
	) {
		self.requestSetPresentationDestination(
			presentationDestination,
			onDismiss: onDismiss
		)
	}

	func makeNavigationRoute<ID: Hashable>(
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

		if node.view.window != nil {
			_setPresentationDestination(
				destination,
				onDismiss: onDismiss
			)
		} else {
			node.view.publisher(for: \.window)
				.filter(\.isNotNil)
				.sink(receiveValue: capture { _self, _ in
					_self._setPresentationDestination(
						destination,
						onDismiss: onDismiss
					)
				})
				.store(in: &windowCancellable)
		}
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

		let __presentNewDestinationIfNeeded: () -> Void = {
			oldDestination?._invalidate()

			if let destination = newDestination {
				let controller = destination._initControllerForPresentationIfNeeded()

				controller.selfDismissPublisher
					.sink(receiveValue: onDismiss)
					.store(in: &router.destinationDismissCancellable)

				self.node.present(controller)
			}

			self.presentedDestination = newDestination
		}

		if router.node.presentedViewController != nil {
			// Cancel current dismiss subscription
			// to avoid dismiss action called on
			// state changes
			router.destinationDismissCancellable = nil
			router.node.dismiss(completion: __presentNewDestinationIfNeeded)
		} else {
			__presentNewDestinationIfNeeded()
		}
	}

	fileprivate func requestNavigationStackSync() {
		guard let node else { return }

		if let navigation = node.navigationController {
			syncNavigationStack(using: navigation)
		} else {
			node.publisher(for: \.navigationController)
				.compactMap { $0 }
				.sink(receiveValue: capture { $0.syncNavigationStack(using: $1) })
				.store(in: &navigationControllerCancellable)
		}
	}

	private func syncNavigationStack(using navigation: UINavigationController) {
		navigationControllerCancellable = nil

		navigation.popPublisher
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

		navigation.setViewControllers(
			buildNavigationStack()
		)
	}
}

// MARK: Build navigation stack

extension CombineNavigationRouter {
	fileprivate func buildNavigationStack() -> [CocoaViewController] {
		parent
			.map { $0.buildNavigationStack() }
			.or(
				[node].compactMap { $0 } +
				self.buildManagedNavigationStack()
			)
	}

	private func buildManagedNavigationStack() -> [CocoaViewController] {
		prepareRoutedControllers().flatMap { controller in
			[controller] + controller.combineNavigationRouter.buildManagedNavigationStack()
		}
	}

	private func prepareRoutedControllers() -> [CocoaViewController] {
		directChildren.compactMap(\.object).flatMap { $0.prepareRoutedControllers() }
		+ routes.compactMap { $0.makeController(routedBy: self) }
	}
}

// MARK: Helpers
#endif

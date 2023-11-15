#if canImport(UIKit) && !os(watchOS)
import Capture
import CocoaAliases
import CombineExtensions
import FoundationExtensions

// MARK: Get/set managed routes

extension CocoaViewController {
	@AssociatedObject
	private var __navigationStack: [NavigationRoute] = []

	@AssociatedObject
	fileprivate var __onDestinationDismiss: (() -> Void)?

	@AssociatedObject
	fileprivate var __destinationDismissCancellable: AnyCancellable?

	internal func routesToDismiss() -> [NavigationRoute] {
		guard let controllers = navigationController?.viewControllers
		else { return [] }

		return __navigationStack.filter { route in
			!controllers.contains { $0.objectID == route.controllerID }
		}
	}

	internal func updateNavigationStack(
		_ navigationStack: [NavigationRoute],
		onDismiss: @escaping () -> Void
	) {
		__onDestinationDismiss = onDismiss
		__navigationStack = navigationStack
		requestNavigationStackSync()
	}

	internal func navigationStackControllers(
		for navigation: UINavigationController
	) -> [CocoaViewController] {
		let navigationStack = __navigationStack
		return zip(navigationStack, navigationStack.indices).flatMap { route, index in
			controller(for: route, in: navigation).map { controller in
				__navigationStack[index].controllerID = controller.objectID
				return [controller] + controller.navigationStackControllers(for: navigation)
			}.or([])
		}
	}
}

// MARK: Configure managed route

extension CocoaViewController {
	@AssociatedObject
	fileprivate var __dismissCancellables: [AnyHashable: AnyCancellable] = [:]

	fileprivate func controller(
		for route: NavigationRoute,
		in navigation: UINavigationController
	) -> CocoaViewController? {
		return route.controller().map { controller in
//			navigation
//				.dismissPublisher(for: self)
//				.sinkValues(capture { _self in
//					_self.__dismissCancellables
//						.removeValue(forKey: route.id)?
//						.cancel()
//					return route.onDismiss()
//				})
//				.store(for: route.id, in: &__dismissCancellables)
			return controller
		}
	}
}

// MARK: Sync navigation stack

extension CocoaViewController {
	@AssociatedObject
	fileprivate var __navigationControllerCancellable: AnyCancellable?

	fileprivate func requestNavigationStackSync() {
		if let navigationController {
			syncNavigationStack(using: navigationController)
		} else {
			publisher(for: \.navigationController)
				.compactMap { $0 }
				.sinkValues(capture { $0.syncNavigationStack(using: $1) })
				.store(in: &__navigationControllerCancellable)
		}
	}

	fileprivate func syncNavigationStack(using navigation: UINavigationController) {
		__navigationControllerCancellable = nil

		navigation.dismissPublisher()
			.sinkValues(capture { _self in
				_self.__onDestinationDismiss?()
			})
			.store(in: &__destinationDismissCancellable)

		navigation.syncNavigationStack(for: self)
	}
}
#endif

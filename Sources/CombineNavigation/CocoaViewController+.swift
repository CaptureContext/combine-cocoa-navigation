#if canImport(UIKit) && !os(watchOS)
import Capture
import CocoaAliases
import CombineExtensions
import FoundationExtensions

// MARK: - Public API

// MARK: navigationStack

extension CocoaViewController {
	public func navigationStack<
		P: Publisher,
		C: Collection & Equatable,
		Route: Hashable
	>(
		for publisher: P,
		switch controller: @escaping (Route) -> UIViewController,
		onDismiss: @escaping (Route) -> Void
	) -> Cancellable where
		P.Output == C,
		P.Failure == Never,
		C.Element == Route
	{
		publisher
			.sinkValues(capture { _self, routes in
				_self.__navigationStack = routes.map { route in
					.init(
						id: route,
						controller: { controller(route) },
						onDismiss: { onDismiss(route) }
					)
				}
			})
	}

	public func navigationStack<
		P: Publisher,
		Stack,
		IDs: Collection & Equatable,
		Route
	>(
		for publisher: P,
		ids: @escaping (Stack) -> IDs,
		route: @escaping (Stack, IDs.Element) -> Route?,
		switch controller: @escaping (Route) -> UIViewController,
		onDismiss: @escaping (IDs.Element) -> Void
	) -> Cancellable where
		P.Output == Stack,
		P.Failure == Never,
		IDs.Element: Hashable
	{
		publisher
			.sinkValues(capture { _self, stack in
				_self.__navigationStack = ids(stack).compactMap { id in
					route(stack, id).map { route in
						.init(
							id: id,
							controller: { controller(route) },
							onDismiss: { onDismiss(id) }
						)
					}
				}
			})
	}
}

// MARK: navigationDestination

extension CocoaViewController {
	public func navigationDestination<P: Publisher>(
		_ id: AnyHashable,
		isPresented publisher: P,
		controller: @escaping () -> CocoaViewController,
		onDismiss: @escaping () -> Void
	) -> AnyCancellable where
		P.Output == Bool,
		P.Failure == Never
	{
		publisher
			.sinkValues(capture { _self, isPresented in
				_self.__navigationStack = isPresented ? [
					.init(
						id: id,
						controller: controller,
						onDismiss: onDismiss
					)
				] : []
			})
	}

	public func navigationDestination<P: Publisher>(
		_ publisher: P,
		switch controller: @escaping (P.Output) -> CocoaViewController,
		onDismiss: @escaping () -> Void
	) -> AnyCancellable where
		P.Output: Hashable & ExpressibleByNilLiteral,
		P.Failure == Never
	{
		publisher
			.sinkValues(capture { _self, route in
				_self.__navigationStack = route == nil ? [] : [
					.init(
						id: route,
						controller: { controller(route) },
						onDismiss: onDismiss
					)
				]
			})
	}
}

// MARK: - Internal API

extension CocoaViewController {
	@AssociatedObject
	internal var __navigationStack: [NavigationRoute] = [] {
		didSet { requestNavigationStackSync() }
	}

	internal func navigationStackControllers(
		for navigation: UINavigationController
	) -> [CocoaViewController] {
		__navigationStack.flatMap { route in
			let controller = controller(for: route, in: navigation)
			return [controller] + controller.navigationStackControllers(for: navigation)
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
	) -> CocoaViewController {
		let controller = route.controller()
		navigation
			.dismissPublisher(for: controller)
			.sinkValues(capture { _self in
				_self.__dismissCancellables.removeValue(forKey: route.id)
				return route.onDismiss()
			})
			.store(for: route.id, in: &__dismissCancellables)
		return controller
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
		navigation.syncNavigationStack(for: self)
	}
}
#endif

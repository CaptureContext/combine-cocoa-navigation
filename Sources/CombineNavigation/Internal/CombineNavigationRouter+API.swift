#if canImport(UIKit) && !os(watchOS)
import Capture
import CocoaAliases
import CombineExtensions
import FoundationExtensions

// MARK: - Public API

// MARK: navigationStack

extension CombineNavigationRouter {
	/// Subscribes on publisher of navigation stack state
	func navigationStack<
		P: Publisher,
		C: Collection & Equatable,
		Route: Hashable
	>(
		_ publisher: P,
		switch controller: @escaping (Route, C.Index) -> CocoaViewController,
		onPop: @escaping ([C.Index]) -> Void
	) -> Cancellable where
		P.Output == C,
		P.Failure == Never,
		C.Element == Route,
		C.Index: Hashable,
		C.Indices: Equatable
	{
		navigationStack(
			publisher,
			ids: \.indices,
			route: { $0[$1] },
			switch: { route, id in
				controller(route, id)
			},
			onPop: onPop
		)
	}

	/// Subscribes on publisher of navigation stack state
	func navigationStack<
		P: Publisher,
		Stack,
		IDs: Collection & Equatable,
		Route
	>(
		_ publisher: P,
		ids: @escaping (Stack) -> IDs,
		route: @escaping (Stack, IDs.Element) -> Route?,
		switch controller: @escaping (Route, IDs.Element) -> CocoaViewController,
		onPop: @escaping ([IDs.Element]) -> Void
	) -> Cancellable where
		P.Output == Stack,
		P.Failure == Never,
		IDs.Element: Hashable
	{
		let getRoutes: (Stack) -> [NavigationRoute] = capture(orReturn: []) { _self, stack in
			ids(stack).compactMap { id in
				route(stack, id).map { route in
					_self.makeNavigationRoute(for: id) { controller(route, id) }
				}
			}
		}

		return publisher
			.sinkValues(capture { _self, stack in
				let managedRoutes = getRoutes(stack)
				
				_self.setRoutes(
					managedRoutes,
					onPop: managedRoutes.isNotEmpty 
					? { poppedRoutes in
						let poppedIDs: [IDs.Element] = poppedRoutes.compactMap { route in
							guard managedRoutes.contains(where: { $0 === route }) else { return nil }
							return route.id as? IDs.Element
						}

						if poppedIDs.isNotEmpty { onPop(poppedIDs) }
					} 
					: nil
				)
			})
	}
}

// MARK: navigationDestination

extension CombineNavigationRouter {
	/// Subscribes on publisher of navigation destination state
	func navigationDestination<P: Publisher>(
		_ id: AnyHashable,
		isPresented publisher: P,
		controller: @escaping () -> CocoaViewController,
		onPop: @escaping () -> Void
	) -> AnyCancellable where
		P.Output == Bool,
		P.Failure == Never
	{
		navigationDestination(
			publisher.map { $0 ? id : nil },
			switch: { _ in controller() },
			onPop: onPop
		)
	}

	/// Subscribes on publisher of navigation destination state
	func navigationDestination<P: Publisher, Route>(
		_ publisher: P,
		switch controller: @escaping (Route) -> CocoaViewController,
		onPop: @escaping () -> Void
	) -> AnyCancellable where
		Route: Hashable,
		P.Output == Optional<Route>,
		P.Failure == Never
	{
		publisher
			.map { [weak self] (route) -> NavigationRoute? in
				guard let self, let route else { return nil }
				return self.makeNavigationRoute(for: route) { controller(route) }
			}
			.sinkValues(capture { _self, route in
				_self.setRoutes(
					route.map { [$0] }.or([]),
					onPop: route.map { route in
						return { poppedRoutes in
							let shouldTriggerPopHandler = poppedRoutes.contains(where: { $0 === route })
							if shouldTriggerPopHandler { onPop() }
						}
					}
				)
			})
	}
}
#endif
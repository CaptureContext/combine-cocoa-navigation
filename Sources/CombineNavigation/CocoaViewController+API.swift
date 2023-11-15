#if canImport(UIKit) && !os(watchOS)
import Capture
import CocoaAliases
import CombineExtensions
import FoundationExtensions

// MARK: - Public API

// MARK: navigationStack

extension CocoaViewController {
	/// Subscribes on publisher of navigation stack state
	public func navigationStack<
		P: Publisher,
		C: Collection & Equatable,
		Route: Hashable
	>(
		_ publisher: P,
		switch controller: @escaping (Route, C.Index) -> CocoaViewController,
		onDismiss: @escaping (Set<C.Index>) -> Void
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
			route: { ($0[$1], $1) },
			switch: controller,
			onDismiss: onDismiss
		)
	}

	/// Subscribes on publisher of navigation stack state
	public func navigationStack<
		P: Publisher,
		Stack,
		IDs: Collection & Equatable,
		Route
	>(
		_ publisher: P,
		ids: @escaping (Stack) -> IDs,
		route: @escaping (Stack, IDs.Element) -> Route?,
		switch controller: @escaping (Route) -> CocoaViewController,
		onDismiss: @escaping (Set<IDs.Element>) -> Void
	) -> Cancellable where
		P.Output == Stack,
		P.Failure == Never,
		IDs.Element: Hashable
	{
		publisher
			.sinkValues(capture { _self, stack in
				_self.updateNavigationStack(
					ids(stack).compactMap { id in
						route(stack, id).map { route in
							.init(
								id: id,
								controller: { controller(route) }
							)
						}
					},
					onDismiss: _self.capture { _self in
						onDismiss(Set(
							_self.routesToDismiss().compactMap { $0.id as? IDs.Element }
						))
					}
				)
			})
	}
}

// MARK: navigationDestination

extension CocoaViewController {
	/// Subscribes on publisher of navigation destination state
	public func navigationDestination<P: Publisher>(
		_ id: AnyHashable,
		isPresented publisher: P,
		controller: @escaping () -> CocoaViewController,
		onDismiss: @escaping () -> Void
	) -> AnyCancellable where
		P.Output == Bool,
		P.Failure == Never
	{
		navigationDestination(
			publisher.map { isPresented in
				isPresented ? id : nil
			},
			switch: { id in
				id.map { _ in controller() }
			},
			onDismiss: {
				onDismiss()
			}
		)
	}

	/// Subscribes on publisher of navigation destination state
	public func navigationDestination<P: Publisher>(
		_ publisher: P,
		switch controller: @escaping (P.Output) -> CocoaViewController?,
		onDismiss: @escaping () -> Void
	) -> AnyCancellable where
		P.Output: Hashable & ExpressibleByNilLiteral,
		P.Failure == Never
	{
		publisher
			.sinkValues(capture { _self, route in
				_self.updateNavigationStack(
					route == nil ? [] : [
						NavigationRoute(
							id: route,
							controller: { controller(route) }
						)
					],
					onDismiss: { [weak self] in
						guard let self, self.routesToDismiss().contains(where: { $0.id == route as AnyHashable })
						else { return }
						onDismiss()
					}
				)
			})
	}
}
#endif

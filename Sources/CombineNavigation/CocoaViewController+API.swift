#if canImport(UIKit) && !os(watchOS)
import Capture
import CocoaAliases
import CombineExtensions
import FoundationExtensions

// MARK: - Public API

// MARK: navigationStack

extension RoutingController {
	/// Subscribes on publisher of navigation stack state
	@inlinable
	public func navigationStack<
		P: Publisher,
		C: Collection & Equatable,
		Route: Hashable
	>(
		_ publisher: P,
		switch destination: @escaping (Destinations, Route) -> any GrouppedDestinationProtocol<C.Index>,
		onPop: @escaping ([C.Index]) -> Void
	) -> Cancellable where
		P.Output == C,
		P.Failure == Never,
		C.Element == Route,
		C.Index: Hashable,
		C.Indices: Equatable
	{
		combineNavigationRouter.navigationStack(
			publisher,
			switch: destinations(destination),
			onPop: onPop
		)
	}

	/// Subscribes on publisher of navigation stack state
	@inlinable
	public func navigationStack<
		P: Publisher,
		Stack,
		IDs: Collection & Equatable,
		Route
	>(
		_ publisher: P,
		ids: @escaping (Stack) -> IDs,
		route: @escaping (Stack, IDs.Element) -> Route?,
		switch destination: @escaping (Destinations, Route) -> any GrouppedDestinationProtocol<IDs.Element>,
		onPop: @escaping ([IDs.Element]) -> Void
	) -> Cancellable where
		P.Output == Stack,
		P.Failure == Never,
		IDs.Element: Hashable
	{
		combineNavigationRouter.navigationStack(
			publisher,
			ids: ids,
			route: route,
			switch: destinations(destination),
			onPop: onPop
		)
	}
}

// MARK: navigationDestination

extension RoutingController {
	/// Subscribes on publisher of navigation destination state
	@inlinable
	public func navigationDestination<P: Publisher>(
		_ id: AnyHashable,
		isPresented publisher: P,
		destination: SingleDestinationProtocol,
		onPop: @escaping () -> Void
	) -> AnyCancellable where
		P.Output == Bool,
		P.Failure == Never
	{
		combineNavigationRouter.navigationDestination(
			id,
			isPresented: publisher,
			destination: destination,
			onPop: onPop
		)
	}

	/// Subscribes on publisher of navigation destination state
	@inlinable
	public func navigationDestination<P: Publisher, Route>(
		_ publisher: P,
		switch destination: @escaping (Destinations, Route) -> SingleDestinationProtocol,
		onPop: @escaping () -> Void
	) -> AnyCancellable where
		Route: Hashable,
		P.Output == Route?,
		P.Failure == Never
	{
		combineNavigationRouter.navigationDestination(
			publisher,
			switch: destinations(destination),
			onPop: onPop
		)
	}
}

// MARK: - Internal helpers

extension RoutingController {
	@usableFromInline
	internal func destinations<Route>(
		_ mapping: @escaping (Destinations, Route) -> SingleDestinationProtocol
	) -> (Route) -> SingleDestinationProtocol {
		let destinations = _makeDestinations()
		return { route in
			mapping(destinations, route)
		}
	}

	@usableFromInline
	internal func destinations<Route, DestinationID: Hashable>(
		_ mapping: @escaping (Destinations, Route) -> any GrouppedDestinationProtocol<DestinationID>
	) -> (Route) -> any GrouppedDestinationProtocol<DestinationID> {
		let destinations = _makeDestinations()
		return { route in
			mapping(destinations, route)
		}
	}
}
#endif

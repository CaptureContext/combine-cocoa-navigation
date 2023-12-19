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
		switch destination: @escaping (Route) -> any GrouppedDestinationProtocol<C.Index>,
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
			switch: destination,
			onPop: onPop
		)
	}

	/// Subscribes on publisher of navigation stack state
	public func navigationStack<
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
		combineNavigationRouter.navigationStack(
			publisher,
			switch: controller,
			onPop: onPop
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
		switch destination: @escaping (Route) -> any GrouppedDestinationProtocol<IDs.Element>,
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
			switch: destination,
			onPop: onPop
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
		switch controller: @escaping (Route, IDs.Element) -> CocoaViewController,
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
			switch: controller,
			onPop: onPop
		)
	}
}

// MARK: navigationDestination

extension CocoaViewController {
	/// Subscribes on publisher of navigation destination state
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
	public func navigationDestination<P: Publisher>(
		_ id: AnyHashable,
		isPresented publisher: P,
		controller: @escaping () -> CocoaViewController,
		onPop: @escaping () -> Void
	) -> AnyCancellable where
		P.Output == Bool,
		P.Failure == Never
	{
		combineNavigationRouter.navigationDestination(
			id,
			isPresented: publisher,
			controller: controller,
			onPop: onPop
		)
	}

	/// Subscribes on publisher of navigation destination state
	public func navigationDestination<P: Publisher, Route>(
		_ publisher: P,
		switch destination: @escaping (Route) -> SingleDestinationProtocol,
		onPop: @escaping () -> Void
	) -> AnyCancellable where
		Route: Hashable,
		P.Output == Route?,
		P.Failure == Never
	{
		combineNavigationRouter.navigationDestination(
			publisher,
			switch: destination,
			onPop: onPop
		)
	}

	/// Subscribes on publisher of navigation destination state
	public func navigationDestination<P: Publisher, Route>(
		_ publisher: P,
		switch controller: @escaping (Route) -> CocoaViewController,
		onPop: @escaping () -> Void
	) -> AnyCancellable where
		Route: Hashable,
		P.Output == Route?,
		P.Failure == Never
	{
		combineNavigationRouter.navigationDestination(
			publisher,
			switch: controller,
			onPop: onPop
		)
	}
}
#endif

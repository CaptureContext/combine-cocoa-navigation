#if canImport(UIKit) && !os(watchOS)
import CocoaAliases

public protocol RoutingController: CocoaViewController {
	associatedtype Destinations
	func _makeDestinations() -> Destinations
}

extension RoutingController {
	private static func _mapNavigationDestinations<each Arg, Output>(
		_ destinations: Destinations,
		_ mapping: @escaping (Destinations, repeat each Arg) -> Output
	) -> (repeat each Arg) -> Output {
		return { (arg: repeat each Arg) in
			mapping(destinations, repeat each arg)
		}
	}

	public func destinations<Route>(
		_ mapping: @escaping (Destinations, Route) -> CocoaViewController
	) -> (Route) -> CocoaViewController {
		Self._mapNavigationDestinations(
			_makeDestinations(),
			mapping
		)
	}

	public func destinations<Route, ID: Hashable>(
		_ mapping: @escaping (Destinations, Route, ID) -> CocoaViewController
	) -> (Route, ID) -> CocoaViewController {
		Self._mapNavigationDestinations(
			_makeDestinations(),
			mapping
		)
	}
}
#endif

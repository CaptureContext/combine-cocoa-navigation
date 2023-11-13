import CocoaAliases
import CombineNavigationMacros

@attached(
	extension,
	conformances: RoutingControllerProtocol,
	names: named(Destinations), named(_makeDestinations())
)
public macro RoutingController() = #externalMacro(
	module: "CombineNavigationMacros",
	type: "RoutingControllerMacro"
)

public protocol RoutingControllerProtocol: CocoaViewController {
	associatedtype Destinations
	func _makeDestinations() -> Destinations
}

extension RoutingControllerProtocol {
	private static func _mapNavigationDestinations<Route, Output>(
		_ destinations: Destinations,
		_ mapping: @escaping (Destinations, Route) -> Output
	) -> (Route) -> Output {
		return { route in
			mapping(destinations, route)
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

	public func destinations<Route>(
		_ mapping: @escaping (Destinations, Route) -> CocoaViewController?
	) -> (Route) -> CocoaViewController?
	where Route: ExpressibleByNilLiteral {
		Self._mapNavigationDestinations(
			_makeDestinations(),
			mapping
		)
	}
}

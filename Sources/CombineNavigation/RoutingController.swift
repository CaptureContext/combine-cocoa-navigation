#if canImport(UIKit) && !os(watchOS)
import CocoaAliases

public protocol RoutingController: CocoaViewController {
	associatedtype Destinations
	func _makeDestinations() -> Destinations
}

extension RoutingController {
	@inlinable
	public func destinations<Route>(
		_ mapping: @escaping (Destinations, Route) -> SingleDestinationProtocol
	) -> (Route) -> SingleDestinationProtocol {
		let destinations = _makeDestinations()
		return { route in
			mapping(destinations, route)
		}
	}

	@inlinable
	public func destinations<Route, DestinationID: Hashable>(
		_ mapping: @escaping (Destinations, Route) -> any GrouppedDestinationProtocol<DestinationID>
	) -> (Route) -> any GrouppedDestinationProtocol<DestinationID> {
		let destinations = _makeDestinations()
		return { route in
			mapping(destinations, route)
		}
	}
}
#endif

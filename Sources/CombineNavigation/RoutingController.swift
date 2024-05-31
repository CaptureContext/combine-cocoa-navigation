#if canImport(UIKit) && !os(watchOS)
import CocoaAliases

public protocol DestinationsProtocol<DestinationType> {
	associatedtype DestinationType
	var allDestinations: [DestinationType] { get }
}

public protocol RoutingController: CocoaViewController {
	associatedtype TreeDestinations: DestinationsProtocol<_TreeDestinationProtocol>
	associatedtype StackDestinations: DestinationsProtocol<_StackDestinationProtocol>
	associatedtype DerivedDestinations: DestinationsProtocol<_DerivedDestinationProtocol>
	associatedtype PresentationDestinations: DestinationsProtocol<_PresentationDestinationProtocol>

	@_spi(Internals)
	func _makeTreeDestinations() -> TreeDestinations
	
	@_spi(Internals)
	func _makeStackDestinations() -> StackDestinations

	@_spi(Internals)
	func _makeDerivedDestinations() -> DerivedDestinations

	@_spi(Internals)
	func _makePresentationDestinations() -> PresentationDestinations
}
#endif

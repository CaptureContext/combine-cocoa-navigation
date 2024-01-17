#if canImport(UIKit) && !os(watchOS)
import CocoaAliases

public protocol RoutingController: CocoaViewController {
	associatedtype Destinations
	func _makeDestinations() -> Destinations
}
#endif

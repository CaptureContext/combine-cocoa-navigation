#if canImport(UIKit) && !os(watchOS)
import CocoaAliases

@attached(
	extension,
	conformances: RoutingController,
	names: named(Destinations), named(_makeDestinations())
)
public macro RoutingController() = #externalMacro(
	module: "CombineNavigationMacros",
	type: "RoutingControllerMacro"
)
#endif

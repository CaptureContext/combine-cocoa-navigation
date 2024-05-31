#if canImport(UIKit) && !os(watchOS)
import CocoaAliases

@attached(
	extension,
	conformances: RoutingController,
	names: 
		named(TreeDestinations),
		named(StackDestinations),
		named(DerivedDestinations),
		named(PresentationDestinations),
		named(_makeTreeDestinations()),
		named(_makeStackDestinations()),
		named(_makeDerivedDestinations()),
		named(_makePresentationDestinations())
)
public macro RoutingController() = #externalMacro(
	module: "CombineNavigationMacros",
	type: "RoutingControllerMacro"
)
#endif

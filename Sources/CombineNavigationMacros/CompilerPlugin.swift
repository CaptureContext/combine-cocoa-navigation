import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct CombineNavigationPlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		RoutingControllerMacro.self
	]
}

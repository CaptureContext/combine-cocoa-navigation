#if canImport(UIKit) && !os(watchOS) && canImport(SwiftUI)
import SwiftUI
import CocoaAliases

public protocol DestinationInitializableControllerProtocol: CocoaViewController {
	static func _init_for_destination() -> CocoaViewController
}

@usableFromInline
func __initializeDestinationController<
	Controller: CocoaViewController
>(
	ofType type: Controller.Type = Controller.self
) -> Controller {
	if
		let controllerType = (Controller.self as? DestinationInitializableControllerProtocol.Type),
		let controller = controllerType._init_for_destination() as? Controller
	{
		return controller
	} else {
		return Controller()
	}
}
#endif

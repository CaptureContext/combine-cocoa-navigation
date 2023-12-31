#if canImport(UIKit) && !os(watchOS) && canImport(SwiftUI)
import SwiftUI
import CocoaAliases

public protocol DestinationInitializableControllerProtocol: CocoaViewController {
	static func _init_for_destination() -> CocoaViewController
}
#endif

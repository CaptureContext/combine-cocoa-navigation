#if canImport(UIKit) && !os(watchOS) && canImport(SwiftUI)
import SwiftUI
import CocoaAliases

public protocol DestinationInitializableControllerProtocol: CocoaViewController {
	init()
}
#endif

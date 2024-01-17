#if canImport(UIKit) && !os(watchOS)
import CocoaAliases

public func bootstrap() {
	CocoaViewController.bootstrapDismissPublisher
	UINavigationController.bootstrapPopPublisher
}
#endif

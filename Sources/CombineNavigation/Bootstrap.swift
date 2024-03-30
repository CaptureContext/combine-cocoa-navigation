#if canImport(UIKit) && !os(watchOS)
import CocoaAliases

public func bootstrap() {
	CocoaViewController.bootstrapAutomaticBindingForRouters
	UINavigationController.bootstrapPopPublisher
}
#endif

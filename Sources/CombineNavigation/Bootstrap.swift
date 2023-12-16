#if canImport(UIKit) && !os(watchOS)
import CocoaAliases

public func bootstrap() {
	UINavigationController.swizzle
}
#endif

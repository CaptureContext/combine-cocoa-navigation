#if canImport(UIKit) && !os(watchOS)
import CocoaAliases

extension UIResponder {
	var __window: UIWindow? {
		guard let window = self as? UIWindow
		else { return next?.__window }
		return window
	}
}
#endif

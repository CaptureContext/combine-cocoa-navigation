#if canImport(UIKit) && !os(watchOS)
import Capture
import CocoaAliases
import CombineExtensions
import FoundationExtensionsMacros

extension CocoaViewController {
	internal static let bootstrapAutomaticBindingForRouters: Void = {
		objc_exchangeImplementations(
			#selector(addChild),
			#selector(__swizzledAddChild)
		)
		objc_exchangeImplementations(
			#selector(removeFromParent),
			#selector(__swizzledRemoveFromParent)
		)
	}()

	@objc dynamic func __swizzledAddChild(_ controller: CocoaViewController) {
		__swizzledAddChild(controller)

		if !self.isKind(of: UINavigationController.self) {
			registerRoutedChild(controller)
		}
	}

	@objc dynamic func __swizzledRemoveFromParent() {
		__swizzledRemoveFromParent()
		combineNavigationRouter.removeFromParent()
	}

	@objc dynamic func __swizzledDidMoveToParent() {
		__swizzledDidMoveToParent()
	}
}
#endif


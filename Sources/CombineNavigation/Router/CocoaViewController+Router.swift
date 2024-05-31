#if canImport(UIKit) && !os(watchOS)
import CocoaAliases
import FoundationExtensionsMacros

extension CocoaViewController {
	@_spi(Internals)
	public var combineNavigationRouter: CombineNavigationRouter {
		getAssociatedObject(forKey: #function) ?? {
			let router = CombineNavigationRouter(self)
			setAssociatedObject(router, forKey: #function)
			return router
		}()
	}

	public func registerRoutedChild(_ controller: CocoaViewController) {
		combineNavigationRouter.addChild(controller.combineNavigationRouter)
	}

	public func unregisterRoutedChild(_ controller: CocoaViewController) {
		combineNavigationRouter.removeChild(controller.combineNavigationRouter)
	}
}
#endif

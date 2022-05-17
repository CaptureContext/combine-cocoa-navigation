#if canImport(UIKit) && !os(watchOS)
import CocoaAliases
import FoundationExtensions

extension CocoaViewController {
  var __erasedRouteConfigurations: Set<RouteConfiguration<AnyHashable>> {
    set { setAssociatedObject(newValue, forKey: #function) }
    get {
      getAssociatedObject(
        of: Set<RouteConfiguration<AnyHashable>>.self,
        forKey: #function
      ).or([])
    }
  }
}
#endif

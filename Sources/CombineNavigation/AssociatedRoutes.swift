#if canImport(UIKit) && !os(watchOS)
import CocoaAliases
import FoundationExtensions

extension CocoaViewController {
  var __erasedRouteConfigurations: Set<RouteConfiguration<AnyHashable>> {
    set { setAssociatedObject(newValue, forKey: #function) }
    get { getAssociatedObject(forKey: #function).or([]) }
  }

  var erasedRouteConfigurations: Set<RouteConfiguration<AnyHashable>> {
    return __erasedRouteConfigurations.union(
      parent
        .map(\.__erasedRouteConfigurations)
        .or([])
    )
  }
  
  public func addRoute(
    _ configuration: RouteConfiguration<AnyHashable>
  ) {
    __erasedRouteConfigurations.insert(configuration)
  }
}
#endif

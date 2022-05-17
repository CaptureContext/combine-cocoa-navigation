#if canImport(UIKit) && !os(watchOS)
import CocoaAliases
import FoundationExtensions

extension UINavigationController {
  func register(
    _ configuration: RouteConfiguration<AnyHashable>
  ) {
    __erasedRouteConfigurations.insert(configuration)
  }
}
#endif

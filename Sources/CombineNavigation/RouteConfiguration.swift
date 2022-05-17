#if canImport(UIKit) && !os(watchOS)
import CocoaAliases

public struct RouteConfiguration<Target: Hashable>: Hashable {
  public static func associate(
    _ controller: @escaping () -> CocoaViewController,
    with target: Target
  ) -> RouteConfiguration { .init(for: controller, target: target) }
  
  public init(
    for controller: @escaping () -> CocoaViewController,
    target: Target
  ) {
    self.getController = controller
    self.target = target
  }
  
  public let getController: () -> CocoaViewController
  public let target: Target
  
  public static func ==(lhs: Self, rhs: Self) -> Bool {
    return lhs.target == rhs.target
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(target)
  }
}
#endif

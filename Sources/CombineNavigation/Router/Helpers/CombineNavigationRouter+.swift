#if canImport(UIKit) && !os(watchOS)
extension CombineNavigationRouter {
	@usableFromInline
	internal var objectID: ObjectIdentifier { .init(self) }
}
#endif

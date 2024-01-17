#if canImport(UIKit) && !os(watchOS)
internal enum NavigationAnimation {
	@TaskLocal static var isEnabled: Bool = true
}
#endif

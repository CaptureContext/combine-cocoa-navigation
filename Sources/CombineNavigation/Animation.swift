#if canImport(UIKit) && !os(watchOS)
public func withNavigationAnimation<R>(
	enabled: Bool = true,
	perform operation: () throws -> R
) rethrows -> R {
	try NavigationAnimation.$enabled.withValue(enabled, operation: operation)
}

public func withNavigationAnimation<R>(
	enabled: Bool = true,
	perform operation: () async throws -> R
) async rethrows -> R {
	try await NavigationAnimation.$enabled.withValue(enabled, operation: operation)
}

internal enum NavigationAnimation {
	@TaskLocal static var enabled: Bool = true
}
#endif

#if canImport(UIKit) && !os(watchOS)
/// Disables navigation animations for the duration of the synchronous operation.
///
/// Basically a convenience function for calling ``withNavigationAnimation(_:perform:file:line:)-76iad``
@discardableResult
public func withoutNavigationAnimation<R>(
	perform operation: () throws -> R,
	file: String = #fileID,
	line: UInt = #line
) rethrows -> R {
	try withNavigationAnimation(
		false,
		perform: operation,
		file: file,
		line: line
	)
}

/// Disables navigation animations for the duration of the asynchronous operation.
///
/// Basically a convenience function for calling ``withNavigationAnimation(_:perform:file:line:)-76iad``
@discardableResult
public func withoutNavigationAnimation<R>(
	perform operation: () async throws -> R,
	file: String = #fileID,
	line: UInt = #line
) async rethrows -> R {
	try await withNavigationAnimation(
		false,
		perform: operation,
		file: file,
		line: line
	)
}

/// Binds task-local NavigationAnimation.isEnabled to the specific value for the duration of the synchronous operation.
///
/// See [TaskLocal.withValue](https://developer.apple.com/documentation/swift/tasklocal/withvalue(_:operation:file:line:)-79atg)
/// for more details
@discardableResult
public func withNavigationAnimation<R>(
	_ enabled: Bool = true,
	perform operation: () throws -> R,
	file: String = #fileID,
	line: UInt = #line
) rethrows -> R {
	try NavigationAnimation.$isEnabled.withValue(
		enabled,
		operation: operation,
		file: file,
		line: line
	)
}

/// Binds task-local NavigationAnimation.isEnabled to the specific value for the duration of the asynchronous operation.
///
/// See [TaskLocal.withValue](https://developer.apple.com/documentation/swift/tasklocal/withvalue(_:operation:file:line:)-1xjor)
/// for more details
@discardableResult
public func withNavigationAnimation<R>(
	_ enabled: Bool = true,
	perform operation: () async throws -> R,
	file: String = #fileID,
	line: UInt = #line
) async rethrows -> R {
	try await NavigationAnimation.$isEnabled.withValue(
		enabled,
		operation: operation,
		file: file,
		line: line
	)
}
#endif

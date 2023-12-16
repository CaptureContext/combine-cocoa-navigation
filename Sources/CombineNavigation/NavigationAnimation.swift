#if canImport(UIKit) && !os(watchOS)
import Combine
import CocoaAliases

extension UINavigationController {
	@discardableResult
	public func popViewController() -> CocoaViewController? {
		popViewController(animated: NavigationAnimation.$isEnabled.get())
	}

	@discardableResult
	public func popToRootViewController() -> [CocoaViewController]? {
		popToRootViewController(animated: NavigationAnimation.$isEnabled.get())
	}

	@discardableResult
	public func popToViewController(
		_ controller: CocoaViewController
	) -> [CocoaViewController]? {
		popToViewController(controller, animated: NavigationAnimation.$isEnabled.get())
	}

	public func setViewControllers(
		_ controllers: [CocoaViewController]
	) {
		setViewControllers(controllers, animated: NavigationAnimation.$isEnabled.get())
	}

	public func pushViewController(_ controller: CocoaViewController) {
		pushViewController(controller, animated: NavigationAnimation.$isEnabled.get())
	}
}

/// Disables navigation animations for the duration of the synchronous operation.
///
/// Basically a convenience function for calling ``withNavigationAnimation(_:perform:file:line:)-76iad``
@discardableResult
public func withoutNavigationAnimation<R>(
	perform operation: () throws -> R,
	file: String = #fileID,
	line: UInt = #line
) rethrows -> R {
	try withNavigationAnimation(false, perform: operation)
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
	try await withNavigationAnimation(false, perform: operation)
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

internal enum NavigationAnimation {
	@TaskLocal static var isEnabled: Bool = true
}

extension Publisher {
	/// Wraps Subscriber.receive calls in ``withNavigationAnimation(_:perform:file:line:)-76iad``
	///
	/// Basically a convenience method for calling ``withNavigationAnimation(_:file:line:)``
	public func withoutNavigationAnimation(
		file: String = #fileID,
		line: UInt = #line
	) -> some Publisher<Output, Failure> {
		return withNavigationAnimation(
			false,
			file: file,
			line: line
		)
	}

	/// Wraps Subscriber.receive calls in ``withNavigationAnimation(_:perform:file:line:)-76iad``
	public func withNavigationAnimation(
		_ enabled: Bool = true,
		file: String = #fileID,
		line: UInt = #line
	) -> some Publisher<Output, Failure> {
		return NavigationAnimationPublisher(
			upstream: self,
			isNavigationAnimationEnabled: enabled,
			file: file,
			line: line
		)
	}
}

private struct NavigationAnimationPublisher<Upstream: Publisher>: Publisher {
	typealias Output = Upstream.Output
	typealias Failure = Upstream.Failure

	var upstream: Upstream
	var isNavigationAnimationEnabled: Bool
	var file: String
	var line: UInt

	func receive<S: Combine.Subscriber>(subscriber: S)
	where S.Input == Output, S.Failure == Failure {
		let conduit = Subscriber(
			downstream: subscriber,
			isNavigationAnimationEnabled: isNavigationAnimationEnabled
		)
		self.upstream.receive(subscriber: conduit)
	}

	private final class Subscriber<Downstream: Combine.Subscriber>: Combine.Subscriber {
		typealias Input = Downstream.Input
		typealias Failure = Downstream.Failure

		let downstream: Downstream
		let isNavigationAnimationEnabled: Bool
		var file: String
		var line: UInt

		init(
			downstream: Downstream,
			isNavigationAnimationEnabled: Bool,
			file: String = #fileID,
			line: UInt = #line
		) {
			self.downstream = downstream
			self.isNavigationAnimationEnabled = isNavigationAnimationEnabled
			self.file = file
			self.line = line
		}

		func receive(subscription: Subscription) {
			self.downstream.receive(subscription: subscription)
		}

		func receive(_ input: Input) -> Subscribers.Demand {
			CombineNavigation.withNavigationAnimation(
				isNavigationAnimationEnabled,
				perform: { self.downstream.receive(input) },
				file: file,
				line: line
			)
		}

		func receive(completion: Subscribers.Completion<Failure>) {
			self.downstream.receive(completion: completion)
		}
	}
}
#endif

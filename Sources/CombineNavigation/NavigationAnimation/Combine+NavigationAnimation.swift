#if canImport(UIKit) && !os(watchOS)
import Combine

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
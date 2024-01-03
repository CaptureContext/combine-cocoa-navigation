#if os(iOS)
import UIKit

public struct Animator {
	private let _run: () -> Void
	private let _stop: () -> Void
	private let _finish: () -> Void

	public func animate() { _run() }
	public func stop() { _stop() }
	public func finish() { _finish() }

	public init(
		run: @escaping () -> Void,
		stop: @escaping () -> Void,
		finish: @escaping () -> Void
	) {
		self._run = run
		self._stop = stop
		self._finish = finish
	}

	public static let empty: Animator = Animator(run: {}, stop: {}, finish: {})
}

public protocol AnimatorProviderProtocol {
	func makeAnimator(for animations: (() -> Void)?) -> Animator
}

public struct InstantAnimatorProvider: AnimatorProviderProtocol {
	public func makeAnimator(for animations: (() -> Void)? = nil) -> Animator {
		Animator(run: { animations?() }, stop: {}, finish: {})
	}
}

public struct UIViewPropertyAnimatorProvider: AnimatorProviderProtocol {
	let duration: TimeInterval
	let metadata: Metadata
	let finalPosition: UIViewAnimatingPosition

	enum Metadata {
		case timingParameters(UITimingCurveProvider)
		case curve(UIView.AnimationCurve)
		case controlPoints(CGPoint, CGPoint)
		case dampingRatio(CGFloat)
	}

	public init(
		duration: TimeInterval,
		timingParameters parameters: UITimingCurveProvider,
		finalPosition: UIViewAnimatingPosition = .end
	) {
		self.duration = duration
		self.metadata = .timingParameters(parameters)
		self.finalPosition = finalPosition
	}

	/// All convenience initializers return an animator which is not running.
	public init(
		duration: TimeInterval,
		curve: UIView.AnimationCurve,
		finalPosition: UIViewAnimatingPosition = .end
	) {
		self.duration = duration
		self.metadata = .curve(curve)
		self.finalPosition = finalPosition
	}

	public init(
		duration: TimeInterval,
		controlPoint1 point1: CGPoint,
		controlPoint2 point2: CGPoint,
		finalPosition: UIViewAnimatingPosition = .end
	) {
		self.duration = duration
		self.metadata = .controlPoints(point1, point2)
		self.finalPosition = finalPosition
	}

	public init(
		duration: TimeInterval,
		dampingRatio ratio: CGFloat,
		finalPosition: UIViewAnimatingPosition = .end
	) {
		self.duration = duration
		self.metadata = .dampingRatio(ratio)
		self.finalPosition = finalPosition
	}

	func makePropertyAnimator(for animations: (() -> Void)? = nil) -> UIViewPropertyAnimator {
		switch metadata {
		case let .timingParameters(parameters):
			let animator = UIViewPropertyAnimator(duration: duration, timingParameters: parameters)
			animator.addAnimations { animations?() }
			return animator

		case let .curve(curve):
			return UIViewPropertyAnimator(
				duration: duration,
				curve: curve,
				animations: animations
			)

		case let .controlPoints(p1, p2):
			return UIViewPropertyAnimator(
				duration: duration,
				controlPoint1: p1,
				controlPoint2: p2,
				animations: animations
			)

		case let .dampingRatio(ratio):
			return UIViewPropertyAnimator(
				duration: duration,
				dampingRatio: ratio,
				animations: animations
			)
		}
	}

	public func makeAnimator(for animations: (() -> Void)? = nil) -> Animator {
		let animator = makePropertyAnimator(for: animations)
		let finalPosition = self.finalPosition
		return Animator(
			run: { animator.startAnimation() },
			stop: { animator.stopAnimation(true) },
			finish: { animator.finishAnimation(at: finalPosition) }
		)
	}
}

public struct UIViewAnimatiorProvider: AnimatorProviderProtocol {
	let duration: TimeInterval
	let delay: TimeInterval
	let options: UIView.AnimationOptions
	let metadata: Metadata

	enum Metadata {
		case spring(initialVelocity: CGFloat, damping: CGFloat)
		case none
	}

	public init(
		duration: TimeInterval,
		delay: TimeInterval = 0,
		options: UIView.AnimationOptions = []
	) {
		self.duration = duration
		self.delay = delay
		self.options = options
		self.metadata = .none
	}

	public init(
		duration: TimeInterval,
		delay: TimeInterval = 0,
		usingSpringWithDamping: CGFloat = 0.5,
		initialSpringVelocity: CGFloat = 3,
		options: UIView.AnimationOptions = []
	) {
		self.duration = duration
		self.delay = delay
		self.options = options
		self.metadata = .spring(
			initialVelocity: initialSpringVelocity,
			damping: usingSpringWithDamping
		)
	}

	public func makeAnimator(
		for animations: (() -> Void)? = nil,
		completion: @escaping ((Bool) -> Void)
	) -> Animator {
		switch metadata {
		case let .spring(initialVelocity, damping):
			return Animator(
				run: {
					UIView.animate(
						withDuration: duration,
						delay: delay,
						usingSpringWithDamping: damping,
						initialSpringVelocity: initialVelocity,
						options: options,
						animations: { animations?() },
						completion: completion
					)
				},
				stop: {},
				finish: {}
			)

		case .none:
			return Animator(
				run: {
					UIView.animate(
						withDuration: duration,
						delay: delay,
						options: options,
						animations: { animations?() },
						completion: completion
					)
				},
				stop: {},
				finish: {}
			)
		}
	}

	public func makeAnimator(
		for animations: (() -> Void)? = nil
	) -> Animator {
		switch metadata {
		case let .spring(initialVelocity, damping):
			return Animator(
				run: {
					UIView.animate(
						withDuration: duration,
						delay: delay,
						usingSpringWithDamping: damping,
						initialSpringVelocity: initialVelocity,
						options: options,
						animations: { animations?() },
						completion: nil
					)
				},
				stop: {},
				finish: {}
			)

		case .none:
			return Animator(
				run: {
					UIView.animate(
						withDuration: duration,
						delay: delay,
						options: options,
						animations: { animations?() },
						completion: nil
					)
				},
				stop: {},
				finish: {}
			)
		}
	}
}
#endif

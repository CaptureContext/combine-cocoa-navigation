#if canImport(UIKit) && !os(watchOS)
import Capture
import CocoaAliases
import Combine
import FoundationExtensions

extension CocoaViewController {
	@AssociatedObject(readonly: true)
	fileprivate var dismissSubject: PassthroughSubject<Void, Never> = .init()

	/// Publisher for dismiss
	///
	/// Emits an event for **dismissed controller** on `dismiss` completion
	///
	/// > It has different behavior from simply observing `dismiss(animated:completion:)`
	/// > selector, the publisher is always called on the dismissed controller
	///
	/// Underlying subject is triggered by swizzled methods in `CombineNavigation` module.
	public var dismissPublisher: some Publisher<Void, Never> {
		return dismissSubject
	}
}

// MARK: - Swizzling
// Swizzle methods that may pop some viewControllers
// with tracking versions which forward popped controllers
// to UINavigationController.popSubject

// Swift swizzling causes infinite recursion for objc methods
//
// Forum:
// https://forums.swift.org/t/dynamicreplacement-causes-infinite-recursion/52768
//
// Swift issues:
// https://github.com/apple/swift/issues/62214
// https://github.com/apple/swift/issues/53916
//
// Have to use objc swizzling
//
//extension CocoaViewController {
//	@_dynamicReplacement(for: dismiss(animated:completion:))
//	public func _trackedDismiss(
//		animated: Bool,
//		completion: (() -> Void)? = nil
//	) {
//		dismiss(animated: animated) {
//			self.dismissSubject.send(())
//			completion?()
//		}
//	}
//}

extension CocoaViewController {
	// Runs once in app lifetime
	internal static let bootstrapDismissPublisher: Void = {
		objc_exchangeImplementations(
			#selector(dismiss(animated:completion:)),
			#selector(__swizzledDismiss)
		)
	}()

	@objc dynamic func __swizzledDismiss(
		animated: Bool,
		completion: (() -> Void)?
	) {
		let dismissedController: UIViewController = presentedViewController ?? self
		__swizzledDismiss(animated: animated, completion: {
			dismissedController.dismissSubject.send(())
			completion?()
		})
	}
}
#endif

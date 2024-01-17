#if canImport(UIKit) && !os(watchOS)
import Capture
import CocoaAliases
import Combine
import FoundationExtensions

extension CocoaViewController {
	@AssociatedObject(readonly: true)
	fileprivate var selfDismissSubject: PassthroughSubject<Void, Never> = .init()

	@AssociatedObject(readonly: true)
	fileprivate var dismissSubject: PassthroughSubject<[CocoaViewController], Never> = .init()

	/// Publisher for dismiss
	///
	/// Emits an event for **dismissed controller** on `dismiss` completion
	///
	/// > It has different behavior from simply observing `dismiss(animated:completion:)`
	/// > selector, the publisher is always called on the dismissed controller
	/// >
	/// > If you need to observe `dismiss(animated:completion:)` selector
	/// > use `dismissPublisher`
	///
	/// Underlying subject is triggered by swizzled methods in `CombineNavigation` module.
	public var selfDismissPublisher: some Publisher<Void, Never> {
		return selfDismissSubject
	}

	/// Publisher for dismiss
	///
	/// Emits an array of dismissed controllers.
	/// If there was no `presentedViewController`s it will emit `[self]` instead
	public var dismissPublisher: some Publisher<[CocoaViewController], Never> {
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
//		let presentationStack = _presentationStack ?? [self]
//
//		let _notifySubjects = {
//			self.dismissSubject.send(presentationStack)
//
//			presentationStack
//				.reversed()
//				.forEach { $0.selfDismissSubject.send(()) }
//		}
//
//		let _completion = {
//			_notifySubjects()
//			completion?()
//		}
//
//		#if canImport(XCTest)
//		dismiss(animated: animated, completion: nil)
//		if !NavigationAnimation.$isEnabled.get() { _completion() }
//		#else
//		dismiss(animated: animated, completion: _completion)
//		#endif
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
		let presentationStack = _presentationStack ?? [self]

		let _notifySubjects = {
			self.dismissSubject.send(presentationStack)

			presentationStack
				.reversed()
				.forEach { $0.selfDismissSubject.send(()) }
		}

		let _completion = {
			_notifySubjects()
			completion?()
		}

		#if canImport(XCTest)
		__swizzledDismiss(animated: animated, completion: nil)
		if !NavigationAnimation.$isEnabled.get() { _completion() }
		#else
		__swizzledDismiss(animated: animated, completion: _completion)
		#endif
	}

	private var _presentationStack: [CocoaViewController]? {
		presentedViewController.map { [$0] + ($0._presentationStack ?? []) }
	}
}
#endif

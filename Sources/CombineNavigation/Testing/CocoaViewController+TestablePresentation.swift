import CocoaAliases

#if canImport(XCTest) && canImport(UIKit) && !os(watchOS)

/// Overrides presentation behaviour specifically
/// for being able to test sequential present/dismiss calls
///
/// Default implementation heavialy relies on lifecycle, requres Window etc.
/// But this one simply assigns presented and presenting controller references
///
/// > Lifecycle events are not guaranteed to trigger
/// > so this implementation might not be suitable
/// > for testing live applications
/// > but fixes unexpected UIKit behaviors
/// > specifically for the needs of this package
@_spi(Testables)
open class AppleSpaghettiCodeTestableController: CocoaViewController {
	private weak var _presentingViewController: CocoaViewController?
	override open var presentingViewController: CocoaViewController? {
		_presentingViewController
	}

	private var _presentedViewController: CocoaViewController?
	override open var presentedViewController: CocoaViewController? {
		_presentedViewController
	}

	@objc dynamic func wasDismissed() {}

	override open func present(
		_ viewControllerToPresent: CocoaViewController,
		animated flag: Bool,
		completion: (() -> Void)? = nil
	) {
		super.present(viewControllerToPresent, animated: flag, completion: completion)

		self._presentedViewController = viewControllerToPresent
		(viewControllerToPresent as? AppleSpaghettiCodeTestableController)?._presentingViewController = self

		completion?()
	}

	override open func dismiss(
		animated flag: Bool,
		completion: (() -> Void)? = nil
	) {
		if let presentedViewController {
			super.dismiss(animated: flag)
			self._presentedViewController = nil
			let dismissedController = presentedViewController as? AppleSpaghettiCodeTestableController
			dismissedController?._presentingViewController = nil
			dismissedController?.wasDismissed()
			completion?()
		} else if let presentingViewController = presentingViewController as? AppleSpaghettiCodeTestableController {
			presentingViewController.dismiss(animated: flag, completion: completion)
		} else if let presentingViewController {
			presentingViewController.dismiss(animated: flag, completion: {
				self._presentingViewController = nil
				self.wasDismissed()
				completion?()
			})
		} else {
			self._presentingViewController = nil
			self.wasDismissed()
			completion?()
		}
	}
}

extension CocoaViewController {
	var _topPresentedController: CocoaViewController? {
		presentedViewController?._topPresentedController ?? self
	}
}
#endif

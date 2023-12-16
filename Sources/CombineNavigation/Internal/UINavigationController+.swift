#if canImport(UIKit) && !os(watchOS)
import Capture
import CocoaAliases
import Combine
import FoundationExtensions

extension UINavigationController {
	private typealias PopSubject = PassthroughSubject<[CocoaViewController], Never>

	private var popSubject: PopSubject {
		getAssociatedObject(forKey: #function) ?? {
			 let subject = PopSubject()
			 setAssociatedObject(subject, forKey: #function)
			 return subject
		 }()
	}

	/// Publisher for popped controllers
	///
	/// Emits an event on calls of:
	/// - `popViewController`
	/// - `popToViewController`
	/// - `popToRootViewController`
	/// - `setViewController` when some controllers are removed  (even if there was pop animation)
	///
	/// Underlying subject is triggered by swizzled methods in `CombineNavigation` module.
	///
	/// > On interactive pop an event will be emitted  only when the pop is finished and is not cancelled
	///
	/// > Is not called when `viewControllers` property is mutated directly
	public var popPublisher: some Publisher<[CocoaViewController], Never> {
		return popSubject
	}

	fileprivate func handlePop(of controllers: [CocoaViewController]) {
		handlePop { self.popSubject.send(controllers) }
	}

	private func handlePop(_ onPop: @escaping () -> Void) {
		guard let transitionCoordinator = self.transitionCoordinator
		else { return onPop() } // Handle non-interactive pop

		// Handle interactive pop if not cancelled
		transitionCoordinator.animate(alongsideTransition: nil) { context in
			if context.isCancelled { return }
			onPop()
		}
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
//extension UINavigationController {
//	@_dynamicReplacement(for: popViewController(animated:))
//	public func _trackedPopViewController(
//		animated: Bool
//	) -> CocoaViewController? {
//		let controller = popViewController(animated: animated)
//		controller.map { handlePop(of: [$0]) }
//		return controller
//	}
//
//	@_dynamicReplacement(for: popToRootViewController(animated:))
//	public func _trackedPopToRootViewController(
//		animated: Bool
//	) -> [CocoaViewController]? {
//		let controllers = popToRootViewController(animated: animated)
//		controllers.map(handlePop)
//		return controllers
//	}
//
//	@_dynamicReplacement(for: popToViewController(_:animated:))
//	public func _trackedPopToViewController(
//		_ controller: CocoaViewController,
//		animated: Bool
//	) -> [CocoaViewController]? {
//		let controllers = popToViewController(controller, animated: animated)
//		controllers.map(handlePop)
//		return controllers
//	}
//
//	@_dynamicReplacement(for: setViewControllers(_:animated:))
//	public func _trackedSetViewControllers(
//		_ controllers: [CocoaViewController],
//		animated: Bool
//	) {
//		let poppedControllers = viewControllers.filter { oldController in
//			!controllers.contains { $0 === oldController }
//		}
//
//		setViewControllers(controllers, animated: animated)
//		handlePop(of: poppedControllers)
//	}
//}

extension UINavigationController {
	// Runs once in app lifetime
	private static let swizzle: Void = {
		objc_exchangeImplementations(
			#selector(popViewController(animated:)),
			#selector(__swizzledPopViewController)
		)

		objc_exchangeImplementations(
			#selector(popToViewController(_:animated:)),
			#selector(__swizzledPopToViewController)
		)

		objc_exchangeImplementations(
			#selector(popToRootViewController(animated:)),
			#selector(__swizzledPopToRootViewController)
		)

		objc_exchangeImplementations(
			#selector(setViewControllers(_:animated:)),
			#selector(__swizzledSetViewControllers)
		)
	}()

	// Swizzle automatically when the first
	// navigationController loads it's view
	open override func loadView() {
		UINavigationController.swizzle
		super.viewDidLoad()
	}

	@objc dynamic func __swizzledPopViewController(
		animated: Bool
	) -> CocoaViewController? {
		let controller = __swizzledPopViewController(animated: animated)
		controller.map { handlePop(of: [$0]) }
		return controller
	}

	@objc dynamic func __swizzledPopToRootViewController(
		animated: Bool
	) -> [CocoaViewController]? {
		let controllers = __swizzledPopToRootViewController(animated: animated)
		controllers.map(handlePop)
		return controllers
	}

	@objc dynamic func __swizzledPopToViewController(
		_ controller: CocoaViewController,
		animated: Bool
	) -> [CocoaViewController]? {
		let controllers = __swizzledPopToViewController(controller, animated: animated)
		controllers.map(handlePop)
		return controllers
	}

	@objc dynamic func __swizzledSetViewControllers(
		_ controllers: [CocoaViewController],
		animated: Bool
	) {
		let poppedControllers = viewControllers.filter { oldController in
			!controllers.contains { $0 === oldController }
		}

		__swizzledSetViewControllers(controllers, animated: animated)
		handlePop(of: poppedControllers)
	}
}
#endif

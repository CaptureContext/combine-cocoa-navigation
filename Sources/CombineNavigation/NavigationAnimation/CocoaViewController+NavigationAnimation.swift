#if canImport(UIKit) && !os(watchOS)
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

extension CocoaViewController {
	public func present(
		_ controller: CocoaViewController,
		completion: (() -> Void)? = nil
	) {
		present(
			controller,
			animated: NavigationAnimation.$isEnabled.get(),
			completion: completion
		)
	}

	public func dismiss(completion: (() -> Void)? = nil) {
		dismiss(
			animated: NavigationAnimation.$isEnabled.get(),
			completion: completion
		)
	}
}
#endif

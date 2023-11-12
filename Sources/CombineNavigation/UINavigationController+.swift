#if canImport(UIKit) && !os(watchOS)
import Capture
import CocoaAliases
import Combine
import FoundationExtensions

extension UINavigationController {
	internal func dismissPublisher(for controller: CocoaViewController) -> some Publisher<Void, Never> {
		let controllerID = controller.objectID
		return Publishers.Merge3(
			publisher(for: #selector(UINavigationController.popViewController)),
			publisher(for: #selector(UINavigationController.popToViewController)),
			publisher(for: #selector(UINavigationController.popToRootViewController))
		)
		.flatMap { [weak self] in Future<Bool, Never> { promise in
			guard let self else { return promise(.success(false)) }

			func controllerIsNotInStack() -> Bool {
				!self.viewControllers.contains { $0.objectID == controllerID }
			}

			guard let transitionCoordinator = self.transitionCoordinator
			else { return promise(.success(controllerIsNotInStack())) } // Handle programmatic pop

			// Handle interactive pop if not cancelled
			transitionCoordinator.animate(alongsideTransition: nil) { context in
				promise(.success(!context.isCancelled && controllerIsNotInStack()))
			}
		}}
		.filter { $0 }
		.replaceOutput(with: ())
	}

	internal func syncNavigationStack(for controller: CocoaViewController) {
		// controller, that manages navigation stack
		// or it's parent, the parent of the pointer
		// must be current navigation controller
		let navigationStackPointer: UIViewController = {
			var pointer = controller
			while pointer.parent !== self {
				guard let parent = pointer.parent else {
					fatalError("Attempt to sync navigationStack from unrelated viewController")
				}
				pointer = parent
			}
			return pointer
		}()

		// controllers before navigation stack managing controller
		let prefix = viewControllers.prefix(while: { $0 !== navigationStackPointer })

		// managed navigation stack
		let suffix = controller.navigationStackControllers(for: self)

		// setViewControllers updates navigation stack with
		// valid push/pop animation, unmanaged controllers are thrown away
		setViewControllers(
			prefix + [navigationStackPointer] + suffix,
			animated: true
		)
	}
}

#endif

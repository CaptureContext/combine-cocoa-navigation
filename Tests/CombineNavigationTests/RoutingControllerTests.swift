import XCTest
import CocoaAliases
import Capture
import Combine
@testable import CombineNavigation
#if canImport(UIKit) && !os(watchOS)
import SwiftUI
#warning("TODO: Add test for `navigationStack(_:ids:route:switch:onDismiss:)`")
#warning("TODO: Add test for `navigationDestination(_:isPresented:controller:onDismiss:)`")
final class RoutingControllerTests: XCTestCase {
  func testAnimation() {
    let viewModel = TreeViewModel()
    let controller = TreeViewController()
    let navigationController = UINavigationController(rootViewController: controller)
    controller.viewModel = viewModel

		XCTAssertEqual(navigationController.viewControllers.count, 1)
		XCTAssert(navigationController.topViewController === controller)

		let expectation = XCTestExpectation()
		_ = withoutNavigationAnimation {
			// Escape out of context, won't work with dispach queues unfortunately
			Task { @MainActor in
				// Wait for 1 second
				try await Task.sleep(nanoseconds: 1_000_000_000)

				// Fails if animation is enabled
				viewModel.state.value.destination = .feedback()
				XCTAssertEqual(navigationController.viewControllers.count, 2)
				XCTAssert(navigationController.topViewController === controller.feedbackController)
				expectation.fulfill()
			}
		}

		wait(for: [expectation], timeout: 1.5)
  }

	func testAnimationPublisher() {
		let viewModel = TreeViewModel()
		let controller = TreeViewController()
		let navigationController = UINavigationController(rootViewController: controller)

		// Disable animations using publisher
		viewModel.animationsDisabled = true
		controller.viewModel = viewModel

		XCTAssertEqual(navigationController.viewControllers.count, 1)
		XCTAssert(navigationController.topViewController === controller)

		// Fails if animation is enabled
		viewModel.state.value.destination = .feedback()
		XCTAssertEqual(navigationController.viewControllers.count, 2)
		XCTAssert(navigationController.topViewController === controller.feedbackController)
 }

	func testNavigationTree() {
		let viewModel = TreeViewModel()
		let controller = TreeViewController()
		let navigationController = UINavigationController(rootViewController: controller)
		controller.viewModel = viewModel

		// Disable navigation animation for tests
		withoutNavigationAnimation {
			XCTAssertEqual(navigationController.viewControllers.count, 1)
			XCTAssert(navigationController.topViewController === controller)

			viewModel.state.value.destination = .feedback()
			XCTAssertEqual(navigationController.viewControllers.count, 2)
			XCTAssert(navigationController.topViewController === controller.feedbackController)

			viewModel.state.value.destination = .orderDetail()
			XCTAssertEqual(navigationController.viewControllers.count, 2)
			XCTAssert(navigationController.topViewController === controller.orderDetailController)

			navigationController.popViewController(animated: false)
			XCTAssertEqual(viewModel.state.value.destination, .none)

			viewModel.state.value.destination = .feedback()
			XCTAssertEqual(navigationController.viewControllers.count, 2)
			XCTAssert(navigationController.topViewController === controller.feedbackController)

			viewModel.state.value.destination = .none
			XCTAssertEqual(navigationController.viewControllers.count, 1)
			XCTAssert(navigationController.topViewController === controller)
		}
	}

	func testNavigationStack() {
		let viewModel = StackViewModel()
		let controller = StackViewController()
		let navigationController = UINavigationController(rootViewController: controller)
		controller.viewModel = viewModel

		// Disable navigation animation for tests
		withoutNavigationAnimation {
			XCTAssertEqual(navigationController.viewControllers.count, 1)
			XCTAssert(navigationController.topViewController === controller)

			viewModel.state.value.path.append(.feedback())
			XCTAssertEqual(navigationController.viewControllers.count, 2)
			XCTAssert(navigationController.topViewController === controller.$feedbackControllers[0])

			viewModel.state.value.path.append(.orderDetail())
			XCTAssertEqual(navigationController.viewControllers.count, 3)
			XCTAssert(navigationController.topViewController === controller.$orderDetailControllers[1])

			viewModel.state.value.path.append(.feedback())
			XCTAssertEqual(navigationController.viewControllers.count, 4)
			XCTAssert(navigationController.topViewController === controller.$feedbackControllers[2])

			viewModel.state.value.path.removeAll()
			XCTAssertEqual(navigationController.viewControllers.count, 1)
			XCTAssert(navigationController.topViewController === controller)

			viewModel.state.value.path.append(.feedback())
			XCTAssertEqual(navigationController.viewControllers.count, 2)
			XCTAssert(navigationController.topViewController === controller.$feedbackControllers[0])

			viewModel.state.value.path.append(.orderDetail())
			XCTAssertEqual(navigationController.viewControllers.count, 3)
			XCTAssert(navigationController.topViewController === controller.$orderDetailControllers[1])

			_ = viewModel.state.value.path.popLast()
			XCTAssertEqual(navigationController.viewControllers.count, 2)
			XCTAssert(navigationController.topViewController === controller.$feedbackControllers[0])

			viewModel.state.value.path.append(.orderDetail())
			XCTAssertEqual(navigationController.viewControllers.count, 3)
			XCTAssert(navigationController.topViewController === controller.$orderDetailControllers[1])

			// pop
			XCTAssertEqual(viewModel.state.value.path.count, 2)
			navigationController.popViewController(animated: false)
			XCTAssertEqual(viewModel.state.value.path.count, 1)

			// popTo
			viewModel.state.value.path = [.feedback(), .feedback(), .orderDetail(), .feedback(), .orderDetail()]
			XCTAssertEqual(navigationController.viewControllers.count, 6)

			navigationController.popToViewController(controller, animated: false)
			XCTAssertEqual(viewModel.state.value.path.count, 0)
			XCTAssertEqual(navigationController.viewControllers.count, 1)

			// popToRoot
			viewModel.state.value.path = [.feedback(), .feedback(), .orderDetail(), .feedback(), .orderDetail()]
			XCTAssertEqual(navigationController.viewControllers.count, 6)

			navigationController.popToRootViewController(animated: false)
			XCTAssertEqual(viewModel.state.value.path.count, 0)
			XCTAssertEqual(navigationController.viewControllers.count, 1)
		}
	}

	func testNavigationStackDestinations() {
		let viewModel = StackViewModel()
		let controller = StackViewController()
		let navigationController = UINavigationController(rootViewController: controller)
		controller.viewModel = viewModel

		// Disable navigation animation for tests
		withoutNavigationAnimation {
			viewModel.state.value.path = [.feedback(), .feedback(), .orderDetail(), .feedback(), .orderDetail()]
			XCTAssertEqual(navigationController.viewControllers.count, 6)

			let destinations = controller._makeDestinations()

			XCTAssert(zip(navigationController.viewControllers, [
				controller,
				controller.feedbackControllers[0],
				controller.feedbackControllers[1],
				controller.orderDetailControllers[2],
				controller.feedbackControllers[3],
				controller.orderDetailControllers[4],
			]).allSatisfy(===))

			XCTAssert(zip(navigationController.viewControllers, [
				controller,
				controller.$feedbackControllers[0],
				controller.$feedbackControllers[1],
				controller.$orderDetailControllers[2],
				controller.$feedbackControllers[3],
				controller.$orderDetailControllers[4],
			]).allSatisfy(===))

			XCTAssert(zip(navigationController.viewControllers, [
				controller,
				destinations.feedbackControllers[0],
				destinations.feedbackControllers[1],
				destinations.orderDetailControllers[2],
				destinations.feedbackControllers[3],
				destinations.orderDetailControllers[4],
			]).allSatisfy(===))

			XCTAssert(zip(navigationController.viewControllers, [
				controller,
				destinations.$feedbackControllers[0],
				destinations.$feedbackControllers[1],
				destinations.$orderDetailControllers[2],
				destinations.$feedbackControllers[3],
				destinations.$orderDetailControllers[4],
			]).allSatisfy(===))

			XCTAssert(zip(navigationController.viewControllers, [
				controller,
				destinations[0],
				destinations[1],
				destinations[2],
				destinations[3],
				destinations[4],
			]).allSatisfy(===))
		}
	}
}

fileprivate let testDestinationID = UUID()

fileprivate class OrderDetailsController: CocoaViewController {}
fileprivate class FeedbackController: CocoaViewController {}

// MARK: - Tree

fileprivate class TreeViewModel {
	struct State {
		enum Destination: Equatable {
			/// UUID represents some state
			case orderDetail(UUID = testDestinationID)
			case feedback(UUID = testDestinationID)

			enum Tag: Hashable {
				case orderDetail
				case feedback
			}

			var tag: Tag {
				switch self {
				case .orderDetail: return .orderDetail
				case .feedback: return .feedback
				}
			}
		}

		var destination: Destination?
	}

	let state = CurrentValueSubject<State, Never>(.init())
	var animationsDisabled: Bool = false

	var publisher: some Publisher<State, Never> {
		animationsDisabled
		? state
			.withNavigationAnimation(false)
			.eraseToAnyPublisher()
		: state
			.eraseToAnyPublisher()
	}
}

@RoutingController
fileprivate class TreeViewController: CocoaViewController {
	private var cancellables: Set<AnyCancellable> = []

	var viewModel: TreeViewModel! {
		didSet { bind(viewModel.publisher) }
	}

	@TreeDestination
	var orderDetailController: OrderDetailsController?

	@TreeDestination
	var feedbackController: FeedbackController?

	func bind<P: Publisher<TreeViewModel.State, Never>>(_ publisher: P) {
		navigationDestination(
			publisher.map(\.destination?.tag).removeDuplicates(),
			switch: destinations { destinations, route in
				switch route {
				case .orderDetail:
					destinations.$orderDetailController()
				case .feedback:
					destinations.$feedbackController()
				case .none:
					nil
				}
			},
			onDismiss: capture { _self in
				_self.viewModel.state.value.destination = .none
			}
		)
		.store(in: &cancellables)
	}
}

// MARK: - Stack

fileprivate class StackViewModel {
	struct State {
		enum Destination {
			/// UUID represents some state
			case orderDetail(UUID = testDestinationID)
			case feedback(UUID = testDestinationID)

			enum Tag: Hashable {
				case orderDetail
				case feedback
			}

			var tag: Tag {
				switch self {
				case .orderDetail: return .orderDetail
				case .feedback: return .feedback
				}
			}
		}

		var path: [Destination] = []
	}

	let state = CurrentValueSubject<State, Never>(.init())
}

@RoutingController
fileprivate class StackViewController: CocoaViewController {
	private var cancellables: Set<AnyCancellable> = []

	var viewModel: StackViewModel! {
		didSet { bind(viewModel.state) }
	}

	@StackDestination
	var orderDetailControllers: [Int: OrderDetailsController]

	@StackDestination
	var feedbackControllers: [Int: FeedbackController]

	func bind<P: Publisher<StackViewModel.State, Never>>(_ publisher: P) {
		navigationStack(
			publisher.map(\.path).map { $0.map(\.tag) }.removeDuplicates(),
			switch: destinations { destinations, route, index in
				switch route {
				case .orderDetail:
					destinations.$orderDetailControllers[index]
				case .feedback:
					destinations.$feedbackControllers[index]
				}
			},
			onDismiss: capture { _self, indices in
				_self.viewModel.state.value.path.remove(atOffsets: IndexSet(indices))
			}
		)
		.store(in: &cancellables)
	}
}
#endif

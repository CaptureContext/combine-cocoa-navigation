import XCTest
import CocoaAliases
import Capture
import Combine
@testable import CombineNavigation

#if canImport(UIKit) && !os(watchOS)

extension XCTestCase {
	@discardableResult
	func withExpectation<T>(
		timeout: TimeInterval,
		execute operation: (XCTestExpectation) -> T
	) -> T {
		let expectation = XCTestExpectation()
		let result = operation(expectation)
		wait(for: [expectation], timeout: timeout)
		return result
	}

	func withExpectations(
		timeout: TimeInterval,
		execute operations: ((XCTestExpectation) -> Void)...
	) {
		withExpectations(
			timeout: timeout,
			execute: operations[...]
		)
	}

	private func withExpectations(
		timeout: TimeInterval,
		execute operations: ArraySlice<(XCTestExpectation) -> Void>
	) {
		guard let operation = operations.first else { return }
		withExpectation(timeout: timeout, execute: operation)
		withExpectations(timeout: timeout, execute: operations.dropFirst())
	}
}

final class NavigationAnimationTests: XCTestCase {
	func expectationWithoutAnimation(
		 delay nanoseconds: UInt64 = 1_000_000_000,
		 execute operation: @escaping (XCTestExpectation) -> Void
	 ) -> (XCTestExpectation) -> Void {
		 return { expectation in
			 _ = withoutNavigationAnimation {
				 // Escape out of context, won't work with dispach queues unfortunately
				 Task { @MainActor in
					 // Wait for 1 second
					 try await Task.sleep(nanoseconds: nanoseconds)
					 operation(expectation)
				 }
			 }
		 }
	 }

	func testAnimationWithTaskDelayUIKitOnly() {
		let rootController = CocoaViewController()
		let navigationController = UINavigationController(rootViewController: rootController)

		XCTAssertEqual(navigationController.viewControllers.count, 1)
		XCTAssert(navigationController.topViewController === rootController)

		withExpectations(
			timeout: 1.5,
			execute: expectationWithoutAnimation { expectation in
				let destinationController = CocoaViewController()
				navigationController.pushViewController(destinationController)

				// Fails if animation is enabled
				XCTAssertEqual(navigationController.viewControllers.count, 2)
				XCTAssert(navigationController.topViewController === destinationController)
				expectation.fulfill()
			},
			expectationWithoutAnimation { expectation in
				navigationController.popViewController()

				// Fails if animation is enabled
				XCTAssertEqual(navigationController.viewControllers.count, 1)
				XCTAssert(navigationController.topViewController === rootController)
				expectation.fulfill()
			},
			expectationWithoutAnimation { expectation in
				let destinationController = CocoaViewController()
				navigationController.pushViewController(CocoaViewController())
				navigationController.pushViewController(CocoaViewController())
				navigationController.pushViewController(destinationController)

				// Fails if animation is enabled
				XCTAssertEqual(navigationController.viewControllers.count, 4)
				XCTAssert(navigationController.topViewController === destinationController)
				expectation.fulfill()
			},
			expectationWithoutAnimation { expectation in
				let destinationController = navigationController.viewControllers[3]
				navigationController.popToViewController(destinationController)

				// Fails if animation is enabled
				XCTAssertEqual(navigationController.viewControllers.count, 4)
				XCTAssert(navigationController.topViewController === destinationController)
				expectation.fulfill()
			},
			expectationWithoutAnimation { expectation in
				let destinationController = CocoaViewController()
				navigationController.setViewControllers([rootController, destinationController])

				// Fails if animation is enabled
				XCTAssertEqual(navigationController.viewControllers.count, 2)
				XCTAssert(navigationController.topViewController === destinationController)
				expectation.fulfill()
			}
		)
	}

	func testAnimationWithTaskDelay() {
		let viewModel = TreeViewModel()
		let controller = TreeViewController()
		let navigationController = UINavigationController(rootViewController: controller)
		controller.viewModel = viewModel

		XCTAssertEqual(navigationController.viewControllers.count, 1)
		XCTAssert(navigationController.topViewController === controller)

		withExpectation(
			timeout: 1.5,
			execute: expectationWithoutAnimation { expectation in
				// Fails if animation is enabled
				viewModel.state.value.destination = .feedback()
				XCTAssertEqual(navigationController.viewControllers.count, 2)
				XCTAssert(navigationController.topViewController === controller.feedbackController)
				expectation.fulfill()
		 }
		)
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
					destinations.$orderDetailController
				case .feedback:
					destinations.$feedbackController
				}
			},
			onPop: capture { _self in
				_self.viewModel.state.value.destination = .none
			}
		)
		.store(in: &cancellables)
	}
}
#endif

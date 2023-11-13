import XCTest
import CocoaAliases
import Capture
import Combine
@testable import CombineNavigation
#if canImport(UIKit) && !os(watchOS)

#warning("TODO: Add test for `navigationStack(_:ids:route:switch:onDismiss:)`")
#warning("TODO: Add test for `navigationDestination(_:isPresented:controller:onDismiss:)`")
final class RoutingControllerTests: XCTestCase {
	func testNavigationTree() {
		let viewModel = TreeViewModel()
		let controller = TreeViewController()
		let navigationController = UINavigationController(rootViewController: controller)
		controller.viewModel = viewModel
		
		// Disable navigation animation for tests
		withNavigationAnimation(enabled: false) {
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
		withNavigationAnimation(enabled: false) {
			XCTAssertEqual(navigationController.viewControllers.count, 1)
			XCTAssert(navigationController.topViewController === controller)

			viewModel.state.value.path.append(.feedback())
			XCTAssertEqual(navigationController.viewControllers.count, 2)
			XCTAssert(navigationController.topViewController === controller.feedbackController)

			viewModel.state.value.path.append(.orderDetail())
			XCTAssertEqual(navigationController.viewControllers.count, 3)
			XCTAssert(navigationController.topViewController === controller.orderDetailController)

			#warning("TODO: Improve Destination for stacks")
			// The problem:
			//
			// In this test we don't push same destinations
			// because there is only one controller for destination available
			//
			// Probably we need to introduce StackDestination type
			// to keep an array of controllers

			viewModel.state.value.path.removeAll()
			XCTAssertEqual(navigationController.viewControllers.count, 1)
			XCTAssert(navigationController.topViewController === controller)

			viewModel.state.value.path.append(.feedback())
			XCTAssertEqual(navigationController.viewControllers.count, 2)
			XCTAssert(navigationController.topViewController === controller.feedbackController)

			viewModel.state.value.path.append(.orderDetail())
			XCTAssertEqual(navigationController.viewControllers.count, 3)
			XCTAssert(navigationController.topViewController === controller.orderDetailController)

			_ = viewModel.state.value.path.popLast()
			XCTAssertEqual(navigationController.viewControllers.count, 2)
			XCTAssert(navigationController.topViewController === controller.feedbackController)

			viewModel.state.value.path.append(.orderDetail())
			XCTAssertEqual(navigationController.viewControllers.count, 3)
			XCTAssert(navigationController.topViewController === controller.orderDetailController)

			navigationController.popViewController(animated: false)
			XCTAssertEqual(viewModel.state.value.path.count, 1)

			viewModel.state.value.path.append(.orderDetail())
			XCTAssertEqual(navigationController.viewControllers.count, 3)
			XCTAssert(navigationController.topViewController === controller.orderDetailController)

			#warning("TODO: Improve dismiss")
			// Fails, probably because:
			//
			// - Navigation pops multiple controllers
			// -> onDismiss removes them from state one-by-one
			// --> when the first one is removed state is updated
			// ---> when state is updated it sends an update to routing controller
			// ----> routing controller updates navigation stack with the state
			//
			// To fix it we probably need to find a way to batch dismiss controllers
			navigationController.popToViewController(controller, animated: false)
			XCTAssertEqual(viewModel.state.value.path.count, 0)
			XCTAssertEqual(navigationController.viewControllers.count, 1)
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
}

@RoutingController
fileprivate class TreeViewController: CocoaViewController {
	private var cancellables: Set<AnyCancellable> = []

	var viewModel: TreeViewModel! {
		didSet { bind(viewModel.state) }
	}

	@Destination
	var orderDetailController: OrderDetailsController?

	@Destination
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

	@Destination
	var orderDetailController: OrderDetailsController?

	@Destination
	var feedbackController: FeedbackController?

	func bind<P: Publisher<StackViewModel.State, Never>>(_ publisher: P) {
		navigationStack(
			publisher.map(\.path).map { $0.map(\.tag) }.removeDuplicates(),
			switch: destinations { destinations, route in
				switch route {
				case .orderDetail:
					destinations.$orderDetailController()
				case .feedback:
					destinations.$feedbackController()
				}
			},
			onDismiss: capture { _self, route in
				guard let index = _self.viewModel.state.value.path.lastIndex(where: { $0.tag == route })
				else { return }
				_self.viewModel.state.value.path.remove(at: index)
			}
		)
		.store(in: &cancellables)
	}
}
#endif

import XCTest
import CocoaAliases
import Capture
import Combine
@testable import CombineNavigation

#if canImport(UIKit) && !os(watchOS)

final class RoutingControllerTreeTests: XCTestCase {
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
}

fileprivate let testDestinationID = UUID()

fileprivate class OrderDetailsController: CocoaViewController {}
fileprivate class FeedbackController: CocoaViewController {}

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

import XCTest
import CocoaAliases
import Capture
import Combine
@testable import CombineNavigation

#if canImport(UIKit) && !os(watchOS)

// TODO: Test deinitialization
// Note: Manual check succeed ✅

final class RoutingControllePresentationTests: XCTestCase {
	static override func setUp() {
		CombineNavigation.bootstrap()
	}

	func testMain() {
		let window = UIWindow(frame: UIScreen.main.bounds)
		let viewModel = PresentationViewModel()
		let controller = PresentationViewController()
		window.rootViewController = controller
		window.makeKeyAndVisible()
		_ = controller.view
		controller.viewModel = viewModel

		// Disable navigation animation for tests
		withoutNavigationAnimation {
			XCTAssert(controller._topPresentedController === controller)

			viewModel.state.value.destination = .feedback()
			XCTAssert(controller._topPresentedController === controller.feedbackController)

			viewModel.state.value.destination = .orderDetail()
			XCTAssert(controller._topPresentedController === controller.orderDetailController)

			controller.dismiss()
			XCTAssertEqual(viewModel.state.value.destination, .none)

			viewModel.state.value.destination = .feedback()
			XCTAssert(controller._topPresentedController === controller.feedbackController)

			viewModel.state.value.destination = .none
			XCTAssert(controller._topPresentedController === controller)
		}
	}
}

fileprivate let testDestinationID = UUID()

fileprivate class OrderDetailsController: CocoaViewController {}
fileprivate class FeedbackController: CocoaViewController {
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		print("Disappear")
	}
}

fileprivate class PresentationViewModel {
	struct State {
		enum Destination: Equatable {
			/// UUID represents some state
			case orderDetail(UUID = testDestinationID)
			case feedback(UUID = testDestinationID)
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
fileprivate class PresentationViewController: CocoaViewController {
	private var cancellables: Set<AnyCancellable> = []

	var viewModel: PresentationViewModel! {
		didSet { bind(viewModel.publisher) }
	}

	@PresentationDestination
	var orderDetailController: OrderDetailsController?

	@PresentationDestination
	var feedbackController: FeedbackController?

	func bind<P: Publisher<PresentationViewModel.State, Never>>(_ publisher: P) {
		presentationDestination(
			publisher.map(\.destination),
			switch: { destinations, route in
				switch route {
				case .orderDetail:
					destinations.$orderDetailController
				case .feedback:
					destinations.$feedbackController
				}
			},
			onDismiss: capture { _self in
				_self.viewModel.state.value.destination = .none
			}
		)
		.store(in: &cancellables)
	}
}
extension CocoaViewController {
	var _topPresentedController: CocoaViewController? {
		if let presentedViewController {
			return presentedViewController._topPresentedController
		} else {
			return self
		}
	}
}

#endif
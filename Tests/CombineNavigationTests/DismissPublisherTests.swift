import XCTest
import CocoaAliases
import Capture
import Combine
import FoundationExtensions
@testable import CombineNavigation

#if canImport(UIKit) && !os(watchOS)

final class DismissPublisherTests: XCTestCase {
	static override func setUp() {
		CombineNavigation.bootstrap()
	}

	func testMain() {
		let expectation1 = self.expectation(description: "1 should track dismissal")
		let expectation2 = self.expectation(description: "2 should track dismissal")
		let expectation3 = self.expectation(description: "Root should track dimsissal")
		expectation1.expectedFulfillmentCount = 2
		expectation2.expectedFulfillmentCount = 2

		@Box
		var dismissCancellables: [ObjectIdentifier: AnyCancellable] = [:]

		let window = UIWindow()
		let root = RootController()
		window.rootViewController = root
		window.makeKeyAndVisible()

		let detail1 = PresentedController1()
		let detail2 = PresentedController2()

		withoutNavigationAnimation {
			let detail = detail1
			let expectation = expectation1

			XCTAssertNil(root.presentedViewController)

			dismissCancellables[detail.objectID] = detail
				.selfDismissPublisher
				.sink { expectation.fulfill() }

			root.present(detail)
			XCTAssertEqual(root.presentedViewController, detail)

			root.dismiss()
			XCTAssertNil(root.presentedViewController)
		}

		withoutNavigationAnimation {
			let detail = detail2
			let expectation = expectation2

			XCTAssertNil(root.presentedViewController)

			dismissCancellables[detail.objectID] = detail
				.selfDismissPublisher
				.sink { expectation.fulfill() }

			root.present(detail)
			XCTAssertEqual(root.presentedViewController, detail)

			root.dismiss()
			XCTAssertNil(root.presentedViewController)
		}

		withoutNavigationAnimation { // nested dismiss
			XCTAssertNil(root.presentedViewController)

			dismissCancellables[root.objectID] = root
				.dismissPublisher
				.sink {
					XCTAssertEqual($0, [detail1, detail2])
					expectation3.fulfill()
				}

			dismissCancellables[detail1.objectID] = detail1
				.selfDismissPublisher
				.sink { expectation1.fulfill() }

			dismissCancellables[detail2.objectID] = detail2
				.selfDismissPublisher
				.sink { expectation2.fulfill() }

			root.present(detail1)
			XCTAssertEqual(root.presentedViewController, detail1)

			detail1.present(detail2)
			XCTAssertEqual(detail1.presentedViewController, detail2)

			root.dismiss()
			XCTAssertNil(root.presentedViewController)
		}

		wait(
			for: [
				expectation1,
				expectation2,
				expectation3
			],
			timeout: 1
		)
	}
}

class RootController: AppleSpaghettiCodeTestableController {}
class PresentedController1: AppleSpaghettiCodeTestableController {}
class PresentedController2: AppleSpaghettiCodeTestableController {}

#endif

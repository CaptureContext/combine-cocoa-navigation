import XCTest
import CocoaAliases
import Capture
import Combine
import FoundationExtensionsMacros
@testable import CombineNavigation

#if canImport(UIKit) && !os(watchOS)

final class DismissPublisherTests: XCTestCase {
	static override func setUp() {
		CombineNavigation.bootstrap()
	}

	func testMain() {
		let expectation1 = self.expectation(description: "1 should track dismissal")
		let expectation2 = self.expectation(description: "2 should track dismissal")
		expectation1.expectedFulfillmentCount = 1
		expectation2.expectedFulfillmentCount = 1

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
				.publishers._testableDismissed
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
				.publishers._testableDismissed
				.sink { expectation.fulfill() }

			root.present(detail)
			XCTAssertEqual(root.presentedViewController, detail)

			root.dismiss()
			XCTAssertNil(root.presentedViewController)
		}

		wait(
			for: [
				expectation1,
				expectation2
			],
			timeout: 1
		)
	}
}

class RootController: AppleSpaghettiCodeTestableController {}
class PresentedController1: AppleSpaghettiCodeTestableController {}
class PresentedController2: AppleSpaghettiCodeTestableController {}

#endif

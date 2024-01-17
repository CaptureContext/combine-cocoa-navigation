import XCTest
import CocoaAliases
import CombineNavigation

#if canImport(UIKit) && !os(watchOS)
final class AppleSpaghettiCodeTestableControllerTests: XCTestCase {
	func testAppleSpaghettiCode() {
		let window = UIWindow()
		let root = AppleSpaghettiCodeTestableController()
		window.rootViewController = root
		window.makeKeyAndVisible()

		let detail1 = AppleSpaghettiCodeTestableController()
		let detail2 = AppleSpaghettiCodeTestableController()

		withoutNavigationAnimation {
			XCTAssertNil(root.presentedViewController)
			root.present(detail1)

			XCTAssertEqual(root.presentedViewController, detail1)
			root.dismiss()

			XCTAssertNil(root.presentedViewController)
			root.present(detail2)

			XCTAssertEqual(root.presentedViewController, detail2)
			root.dismiss()

			XCTAssertNil(root.presentedViewController)
		}
	}
}
#endif

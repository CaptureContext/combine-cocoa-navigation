import XCTest
import CocoaAliases
@_spi(Internals) @testable import CombineNavigation

#if canImport(UIKit) && !os(watchOS)
final class DestinationTests: XCTestCase {
	func testMain() {
		@Destination
		var basic: CustomViewController?

		@Destination({ .init(value: 1) })
		var configuredBasic: CustomViewController?

		XCTAssertEqual(_basic().value, 0)
		XCTAssertEqual(_configuredBasic().value, 1)

		XCTAssertEqual(_basic().isConfiguredByCustomNavigationChild, false)
		XCTAssertEqual(_configuredBasic().isConfiguredByCustomNavigationChild, false)
	}

	func testInheritance() {
		@CustomDestination
		var custom: CustomViewController?

		@CustomDestination({ .init(value: 2) })
		var configuredCustom: CustomViewController?

		XCTAssertEqual(_custom().value, 1)
		XCTAssertEqual(_configuredCustom().value, 2)

		XCTAssertEqual(_custom().isConfiguredByCustomNavigationChild, true)
		XCTAssertEqual(_configuredCustom().isConfiguredByCustomNavigationChild, true)

		// Should compile to pass the test
		_custom.customNavigationChildSpecificMethod()

		// Should compile to pass the test
		$custom.customNavigationChildSpecificMethod()
	}
}

fileprivate class CustomViewController: CocoaViewController {
	var value: Int = 0
	var isConfiguredByCustomNavigationChild: Bool = false

	convenience init() {
		self.init(value: 0)
	}

	required init(value: Int) {
		super.init(nibName: nil, bundle: nil)
		self.value = value
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
}

@propertyWrapper
fileprivate final class CustomDestination<Controller: CustomViewController>: Destination<Controller> {
	override var wrappedValue: Controller? { super.wrappedValue }
	override var projectedValue: CustomDestination<Controller> { super.projectedValue as! Self }

	func customNavigationChildSpecificMethod() { }

	/// Override this method to apply initial configuration to the controller
	///
	/// `CombineNavigation` should be imported as `@_spi(Internal) import`
	/// to override this declaration
	override func configureController(_ controller: Controller) {
		controller.isConfiguredByCustomNavigationChild = true
	}

	/// This wrapper is binded to a custom controller type
	/// so you can override wrapper's `initController` method
	/// to call some specific initializer
	///
	/// `CombineNavigation` should be imported as `@_spi(Internal) import`
	/// to override this declaration 
	override class func initController() -> Controller {
		.init(value: 1)
	}
}
#endif

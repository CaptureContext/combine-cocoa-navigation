import XCTest
import CocoaAliases
@_spi(Internals) @testable import CombineNavigation

#if canImport(UIKit) && !os(watchOS)
final class TreeDestinationTests: XCTestCase {
	func testMain() {
		@TreeDestination
		var sut: CustomViewController?

		@TreeDestination({ .init(value: 1) })
		var configuredSUT: CustomViewController?

		XCTAssertEqual(_sut().value, 0)
		XCTAssertEqual(_configuredSUT().value, 1)

		XCTAssertEqual(_sut().isConfiguredByCustomNavigationChild, false)
		XCTAssertEqual(_configuredSUT().isConfiguredByCustomNavigationChild, false)
	}

	func testInheritance() {
		@CustomTreeDestination
		var sut: CustomViewController?

		@CustomTreeDestination({ .init(value: 2) })
		var configuredSUT: CustomViewController?

		XCTAssertEqual(_sut().value, 1)
		XCTAssertEqual(_configuredSUT().value, 2)

		XCTAssertEqual(_sut().isConfiguredByCustomNavigationChild, true)
		XCTAssertEqual(_configuredSUT().isConfiguredByCustomNavigationChild, true)

		// Should compile to pass the test
		_sut.customNavigationChildSpecificMethod()

		// Should compile to pass the test
		$sut.customNavigationChildSpecificMethod()
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
fileprivate final class CustomTreeDestination<Controller: CustomViewController>: TreeDestination<Controller> {
	override var wrappedValue: Controller? { super.wrappedValue }
	override var projectedValue: CustomTreeDestination<Controller> { super.projectedValue as! Self }

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
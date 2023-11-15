import XCTest
import CocoaAliases
@_spi(Internals) @testable import CombineNavigation

#if canImport(UIKit) && !os(watchOS)
final class StackDestinationTests: XCTestCase {
	func testMain() {
		@StackDestination
		var sut: [AnyHashable: CustomViewController]

		@StackDestination({ .init(value: 1) })
		var configuredSUT: [AnyHashable: CustomViewController]

		var mergedNavigationStack: [CustomViewController] = []

		var navigationStackState: [Int] = []
		func peekStackID() -> Int? { navigationStackState.indices.last }

		do { navigationStackState.append(0) // add first
			mergedNavigationStack.append(_sut[peekStackID()])

			XCTAssertNotEqual(sut[peekStackID()], nil)
			XCTAssertEqual(configuredSUT[peekStackID()], nil)

			XCTAssert(_sut[peekStackID()] === sut[peekStackID()])
			XCTAssert(_sut[peekStackID()] === mergedNavigationStack.last)
			XCTAssert(_configuredSUT[peekStackID()] !== mergedNavigationStack.last)
		}

		do { navigationStackState.append(0) // add second
			mergedNavigationStack.append(_configuredSUT[peekStackID()])

			XCTAssertNotEqual(configuredSUT[peekStackID()], nil)
			XCTAssertEqual(sut[peekStackID()], nil)

			XCTAssert(_configuredSUT[peekStackID()] === configuredSUT[peekStackID()])
			XCTAssert(_configuredSUT[peekStackID()] === mergedNavigationStack.last)
			XCTAssert(_sut[peekStackID()] !== mergedNavigationStack.last)
		}

		do {
			XCTAssertEqual(sut[0]?.isConfiguredByCustomNavigationChild, false)
			XCTAssertEqual(sut[0]?.value, 0)

			XCTAssertEqual(configuredSUT[1]?.isConfiguredByCustomNavigationChild, false)
			XCTAssertEqual(configuredSUT[1]?.value, 1)
		}

		do { navigationStackState.append(0) // add third
			mergedNavigationStack.append(_sut[peekStackID()])

			XCTAssertNotEqual(sut[peekStackID()], nil)
			XCTAssertEqual(configuredSUT[peekStackID()], nil)

			XCTAssert(zip(mergedNavigationStack, [
				sut[0],
				configuredSUT[1],
				sut[2]
			].compactMap { $0 }).allSatisfy(===))

			XCTAssert(_sut[peekStackID()] === sut[peekStackID()])
		}
	}

	func testInheritance() {
		@CustomStackDestination
		var sut: [AnyHashable: CustomViewController]

		@CustomStackDestination({ .init(value: 2) })
		var configuredSUT: [AnyHashable: CustomViewController]

		XCTAssertEqual(_sut[0].value, 1)
		XCTAssertEqual(_configuredSUT[0].value, 2)

		XCTAssertEqual(_sut[0].isConfiguredByCustomNavigationChild, true)
		XCTAssertEqual(_configuredSUT[0].isConfiguredByCustomNavigationChild, true)

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
fileprivate final class CustomStackDestination<
	StackElementID: Hashable,
	Controller: CustomViewController
>: StackDestination<
	StackElementID,
	Controller
> {
	override var wrappedValue: [StackElementID: Controller] {
		super.wrappedValue
	}

	override var projectedValue: CustomStackDestination<StackElementID, Controller> {
		super.projectedValue as! Self
	}

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

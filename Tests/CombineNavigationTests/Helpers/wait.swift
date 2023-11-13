import XCTest
import FoundationExtensions

#warning("TODO: Remove before release if not used")
extension XCTestCase {
	func wait(for interval: TimeInterval) {
		let expectation = XCTestExpectation()
		
		DispatchQueue.main.asyncAfter(deadline: .interval(interval)) {
			expectation.fulfill()
		}

		wait(for: [expectation], timeout: interval + 0.5)
	}
}

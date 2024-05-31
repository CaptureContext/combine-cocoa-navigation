#if canImport(UIKit) && !os(watchOS)
import CombineCocoaMacros
import CocoaAliases

extension PublishersProxy where Base: CocoaViewController {
	@_spi(Testables)
	public var _testableDismissed: some Publisher<Void, Never> {
		#if canImport(XCTest)
		if let controller = base.as(AppleSpaghettiCodeTestableController.self) {
			return controller.publisher(
				for: #selector(AppleSpaghettiCodeTestableController.wasDismissed)
			).eraseToAnyPublisher()
		} else {
			return dismissed.eraseToAnyPublisher()
		}
		#else
		return dismissed
		#endif
	}
}

extension PublishersProxy where Base: CocoaView {

	@_spi(Testables)
	public var _testableIsReadyForPresenting: some Publisher<Bool, Never> {
		#if canImport(XCTest)
		return Just(true)
		#else
		return isReadyForPresenting
		#endif
	}

	public var isReadyForPresenting: some Publisher<Bool, Never> {
		return Publishers.Merge(
			Just(base.window.isNotNil),
			base.publisher(for: #selector(UIView.didMoveToWindow))
				.compactMap { [weak base] in base?.window.isNotNil }
		)
	}
}
#endif

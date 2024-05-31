#if canImport(UIKit) && !os(watchOS)
import Capture
import CocoaAliases

extension CombineNavigationRouter {
	@_spi(Internals)
	public class NavigationRoute: Identifiable {
		public let id: AnyHashable

		public let routingControllerID: ObjectIdentifier
		private(set) public var routedControllerID: ObjectIdentifier?

		private let controller: ((CocoaViewController) -> Void) -> CocoaViewController?
		let invalidationHandler: (() -> Void)?

		public init(
			id: AnyHashable,
			routingControllerID: ObjectIdentifier,
			controller: @escaping ((CocoaViewController) -> Void) -> CocoaViewController?,
			invalidationHandler: (() -> Void)?
		) {
			self.id = id
			self.routingControllerID = routingControllerID
			self.controller = controller
			self.invalidationHandler = invalidationHandler
		}

		@discardableResult
		public func makeController(
			routedBy parentRouter: CombineNavigationRouter
		) -> CocoaViewController? {
			let controller = self.controller { controller in
				parentRouter.addChild(controller.combineNavigationRouter)
			}
			routedControllerID = controller?.objectID
			return controller
		}
	}
}
#endif

#if canImport(UIKit) && !os(watchOS)
import CocoaAliases
import FoundationExtensions
import Combine

struct NavigationRouteIndexedID<
	Route: Hashable,
	Index: Hashable
>: Hashable {
	let route: Route
	let index: Index
}

struct NavigationRoute: Hashable, Equatable, Identifiable {
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.id == rhs.id
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}

	let id: AnyHashable
	var controllerID: ObjectIdentifier?
	let controller: () -> CocoaViewController?

	init(
		id: AnyHashable,
		controller: @escaping () -> CocoaViewController?
	) {
		self.id = id
		self.controller = controller
	}
}
#endif

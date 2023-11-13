#if canImport(UIKit) && !os(watchOS)
import CocoaAliases
import FoundationExtensions
import Combine

struct NavigationRoute: Hashable, Equatable, Identifiable {
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.id == rhs.id
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}

	let id: AnyHashable
	let controller: () -> CocoaViewController?
	let onDismiss: () -> Void

	init(
		id: AnyHashable,
		controller: @escaping () -> CocoaViewController?,
		onDismiss: @escaping () -> Void
	) {
		self.id = id
		self.controller = controller
		self.onDismiss = onDismiss
	}
}
#endif

#if canImport(UIKit) && !os(watchOS)
import CocoaAliases

extension CocoaView {
	func isNestedSubview(of parent: CocoaView) -> Bool {
		superview === parent || superview?.isNestedSubview(of: parent) == true
	}
}
#endif

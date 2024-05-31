import Foundation

extension NSObject {
	@usableFromInline
	internal var objectID: ObjectIdentifier { .init(self) }
}

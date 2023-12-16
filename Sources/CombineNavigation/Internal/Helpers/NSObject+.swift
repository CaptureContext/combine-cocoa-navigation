import Foundation

extension NSObject {
	internal var objectID: ObjectIdentifier { .init(self) }
}

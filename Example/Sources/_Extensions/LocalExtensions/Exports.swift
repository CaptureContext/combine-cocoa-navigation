@_exported import CocoaExtensions
@_exported import IdentifiedCollections
@_exported import CombineExtensions

extension USID {
	public static func uuid() -> Self { .init(UUID()) }
}

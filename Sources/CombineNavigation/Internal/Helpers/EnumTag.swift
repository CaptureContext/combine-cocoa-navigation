@_spi(Reflection) import CasePaths

/// Index of enum case in its declaration
@usableFromInline
internal func enumTag<Case>(_ `case`: Case) -> UInt32? {
	EnumMetadata(Case.self)?.tag(of: `case`)
}

extension Optional {
	/// Index of enum case in its declaration
	@usableFromInline
	internal static func compareTagsEqual(
		lhs: Self,
		rhs: Self
	) -> Bool {
		let wrapped: Bool = enumTag(lhs) == enumTag(rhs)
		let unwrapped: Bool = lhs.flatMap(enumTag) == rhs.flatMap(enumTag)
		return wrapped && unwrapped
	}
}
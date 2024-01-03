public struct Unit: Codable, Equatable, Hashable {
	public init() {}
}

public let unit = Unit()

extension Unit {
	@inlinable
	public init(from decoder: Decoder) throws { self.init() }

	@inlinable
	public func encode(to encoder: Encoder) throws {}
}

extension Unit {
	@inlinable
	public static func == (_: Unit, _: Unit) -> Bool {
		return true
	}
}

extension Unit { // Monoid
	public static var empty: Unit = unit
}

extension Unit: Error {}

extension Unit: ExpressibleByNilLiteral {
	@inlinable
	public init(nilLiteral: ()) {
		self.init()
	}
}

import FoundationExtensions

// TODO: Move to FoundationExtensions
extension Equated.Comparator {
	public static func const(_ result: Bool) -> Self {
		return .custom { _, _ in result }
	}
}

extension Equated where Value == Void {
	public static var void: Self {
		return .init((), by: .const(true))
	}
}

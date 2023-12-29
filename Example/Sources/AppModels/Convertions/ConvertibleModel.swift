public protocol ConvertibleModel {}

extension ConvertibleModel {
	public func convert<Value>(to convertion: Convertion<Self, Value>) -> Value {
		return convertion.convert(self)
	}
}

public struct Convertion<From, To> {
	private let _convert: (From) -> To

	public init(_ convert: @escaping (From) -> To) {
		self._convert = convert
	}

	func convert(_ value: From) -> To {
		return _convert(value)
	}
}

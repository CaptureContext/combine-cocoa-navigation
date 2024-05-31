@inlinable
internal func reduce<Value>(
	into value: Value,
	transform: (inout Value) -> Void
) -> Value {
	var copy = value
	transform(&copy)
	return copy
}

extension Collection {
	var isNotEmpty: Bool { !isEmpty }
}

import Combine

extension AnyCancellable {
	@usableFromInline
	internal func store<Key: Hashable>(
		for key: Key,
		in cancellables: inout [Key: AnyCancellable]
	) {
		cancellables[key] = self
	}

	@usableFromInline
	internal func store(
		in cancellable: inout AnyCancellable?
	) {
		cancellable = self
	}
}

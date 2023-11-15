import Combine

extension AnyCancellable {
	internal func store<Key: Hashable>(
		for key: Key,
		in cancellables: inout [Key: AnyCancellable]
	) {
		cancellables[key] = self
	}

	internal func store(
		in cancellable: inout AnyCancellable?
	) {
		cancellable = self
	}
}

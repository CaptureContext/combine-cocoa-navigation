import _Dependencies
import LocalExtensions
import Combine

extension DependencyValues {
	public var currentUser: CurrentUserIDContainer {
		get { self[CurrentUserIDContainer.self] }
		set { self[CurrentUserIDContainer.self] = newValue }
	}
}

public struct CurrentUserIDContainer {
	private let _idSubject: CurrentValueSubject<USID?, Never>

	public var id: USID? {
		get { _idSubject.value }
		nonmutating set { _idSubject.send(newValue) }
	}

	public var idPublisher: some Publisher<USID?, Never> {
		return _idSubject
	}

	public init(id: USID? = nil) {
		self._idSubject = .init(id)
	}
}

extension CurrentUserIDContainer: DependencyKey {
	public static var liveValue: CurrentUserIDContainer { .init() }
	public static var previewValue: CurrentUserIDContainer { .init() }
}

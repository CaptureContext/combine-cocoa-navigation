import _Dependencies
import LocalExtensions

extension DependencyValues {
	public var currentUser: CurrentUserIDContainer {
		get { self[CurrentUserIDContainer.self] }
		set { self[CurrentUserIDContainer.self] = newValue }
	}
}

public struct CurrentUserIDContainer {
	@Reference
	public var id: USID?

	public init(id: USID? = nil) {
		self.id = id
	}
}

extension CurrentUserIDContainer: DependencyKey {
	public static var liveValue: CurrentUserIDContainer { .init() }
	public static var previewValue: CurrentUserIDContainer { .init() }
}

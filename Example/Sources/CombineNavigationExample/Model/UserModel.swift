import Foundation

public struct UserModel: Equatable, Identifiable {
	public var id: UUID
	public var username: String
	public var avatarURL: URL?

	public init(
		id: UUID,
		username: String,
		avatarURL: URL? = nil
	) {
		self.id = id
		self.username = username
		self.avatarURL = avatarURL
	}
}

extension UserModel {
	static var mockCacheByID: [UUID: UserModel] = [:]
	static var mockCacheByUsername: [String: UserModel] = [:]

	public static func mock(
		id: UUID = .init(),
		username: String = "username",
		avatarURL: URL? = nil
	) -> Self {
		let user = mockCacheByID[id] ?? mockCacheByUsername[username] ?? UserModel(
			id: id,
			username: username,
			avatarURL: avatarURL
		)
		mockCacheByID[user.id] = user
		mockCacheByUsername[user.username] = user
		return user
	}
}

import LocalExtensions

public struct UserModel: Equatable, Identifiable {
	public var id: USID
	public var username: String
	public var displayName: String
	public var bio: String
	public var avatarURL: URL?

	public init(
		id: USID,
		username: String,
		displayName: String = "",
		bio: String = "",
		avatarURL: URL? = nil
	) {
		self.id = id
		self.username = username
		self.displayName = displayName
		self.bio = bio
		self.avatarURL = avatarURL
	}
}

extension UserModel {
	static var mockCacheByID: [USID: UserModel] = [:]
	static var mockCacheByUsername: [String: UserModel] = [:]

	public static func mock(
		id: USID = .init(),
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

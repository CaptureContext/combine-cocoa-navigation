import LocalExtensions

public struct UserInfoModel: Equatable, Identifiable, ConvertibleModel {
	public var id: USID
	public var username: String
	public var displayName: String
	public var bio: String
	public var avatarURL: URL?
	public var isFollowingYou: Bool
	public var isFollowedByYou: Bool
	public var followsCount: Int
	public var followersCount: Int
	public var tweetsCount: Int
	
	public init(
		id: USID,
		username: String,
		displayName: String = "",
		bio: String = "",
		avatarURL: URL? = nil,
		isFollowingYou: Bool = false,
		isFollowedByYou: Bool = false,
		followsCount: Int = 0,
		followersCount: Int = 0,
		tweetsCount: Int = 0
	) {
		self.id = id
		self.username = username
		self.displayName = displayName
		self.bio = bio
		self.avatarURL = avatarURL
		self.isFollowingYou = isFollowingYou
		self.isFollowedByYou = isFollowedByYou
		self.followsCount = followsCount
		self.followersCount = followersCount
		self.tweetsCount = tweetsCount
	}
}

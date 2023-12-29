import LocalExtensions

public struct TweetModel: Equatable, Identifiable, Codable, ConvertibleModel {
	public struct AuthorModel: Equatable, Identifiable, Codable, ConvertibleModel {
		public var id: USID
		public var avatarURL: URL?
		public var username: String

		public init(
			id: USID,
			avatarURL: URL? = nil,
			username: String
		) {
			self.id = id
			self.avatarURL = avatarURL
			self.username = username
		}
	}

	public var id: USID
	public var author: AuthorModel
	public var replyTo: USID?
	public var repliesCount: Int
	public var isLiked: Bool
	public var likesCount: Int
	public var isReposted: Bool
	public var repostsCount: Int
	public var text: String

	public init(
		id: USID,
		author: AuthorModel,
		replyTo: USID? = nil,
		repliesCount: Int = 0,
		isLiked: Bool = false,
		likesCount: Int = 0,
		isReposted: Bool = false,
		repostsCount: Int = 0,
		text: String
	) {
		self.id = id
		self.author = author
		self.replyTo = replyTo
		self.repliesCount = repliesCount
		self.isLiked = isLiked
		self.likesCount = likesCount
		self.isReposted = isReposted
		self.repostsCount = repostsCount
		self.text = text
	}
}

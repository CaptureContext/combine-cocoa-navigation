import LocalExtensions

public struct TweetModel: Equatable, Identifiable, Codable {
	public var id: USID
	public var authorID: USID
	public var replyTo: USID?
	public var repliesCount: Int
	public var isLiked: Bool
	public var likesCount: Int
	public var isReposted: Bool
	public var repostsCount: Int
	public var text: String

	public init(
		id: USID,
		authorID: USID,
		replyTo: USID? = nil,
		repliesCount: Int = 0,
		isLiked: Bool = false,
		likesCount: Int = 0,
		isReposted: Bool = false,
		repostsCount: Int = 0,
		text: String
	) {
		self.id = id
		self.authorID = authorID
		self.replyTo = replyTo
		self.repliesCount = repliesCount
		self.isLiked = isLiked
		self.likesCount = likesCount
		self.isReposted = isReposted
		self.repostsCount = repostsCount
		self.text = text
	}
}

extension TweetModel {
	public static func mock(
		id: USID = .init(),
		authorID: USID = UserModel.mock().id,
		replyTo: USID? = nil,
		text: String =  """
		Nisi commodo non ea consequat qui ad pariatur dolore elit ipsum laboris ipsum. \
		Culpa anim incididunt sunt minim ut eiusmod nulla mollit minim qui. \
		In ad laboris labore irure ea ea officia.
		"""
	) -> TweetModel {
		.init(
			id: id,
			authorID: authorID,
			replyTo: replyTo,
			text: text
		)
	}

	public func withReplies(
		@TweetModelsBuilder replies: (TweetModel) -> [TweetModel]
	) -> [TweetModel] {
		[self] + replies(self)
	}
}

@resultBuilder
public struct TweetModelsBuilder: ArrayBuilderProtocol {
	public typealias Element = TweetModel
}

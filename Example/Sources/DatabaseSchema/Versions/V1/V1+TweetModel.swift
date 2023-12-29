import SwiftData
import LocalExtensions

extension DatabaseSchema.V1 {
	@Model
	public final class TweetModel: Equatable, Identifiable, Sendable {
		@Attribute(.unique)
		public let id: String
		public var createdAt: Date

		@Relationship(inverse: \UserModel.tweets)
		public var author: UserModel

		@Relationship
		public var repostSource: TweetModel?

		@Relationship
		public var replySource: TweetModel?

		@Relationship(inverse: \TweetModel.replySource)
		public var replies: [TweetModel]

		@Relationship(inverse: \TweetModel.repostSource)
		public var reposts: [TweetModel]

		@Relationship(inverse: \UserModel.likedTweets)
		public var likes: [UserModel]

		public var content: String

		public init(
			id: USID,
			createdAt: Date = .now,
			author: UserModel,
			repostSource: TweetModel? = nil,
			replySource: TweetModel? = nil,
			replies: [TweetModel] = [],
			reposts: [TweetModel] = [],
			likes: [UserModel] = [],
			content: String
		) {
			self.id = id.rawValue
			self.createdAt = createdAt
			self.author = author
			self.repostSource = repostSource
			self.replySource = replySource
			self.replies = replies
			self.reposts = reposts
			self.likes = likes
			self.content = content
		}
	}
}

import SwiftData
import LocalExtensions

extension DatabaseSchema.V1 {
	@Model
	public final class TweetModel: Equatable, Identifiable, @unchecked Sendable {
		@Attribute(.unique)
		public let id: String
		public var createdAt: Date

		public var author: UserModel?

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
			content: String
		) {
			self.id = id.rawValue
			self.createdAt = createdAt
			self.content = content
			self.replies = []
			self.reposts = []
			self.likes = []
		}
	}
}

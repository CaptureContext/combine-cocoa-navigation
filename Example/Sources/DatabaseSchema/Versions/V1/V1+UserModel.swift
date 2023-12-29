import SwiftData
import LocalExtensions

extension DatabaseSchema.V1 {
	@Model
	public final class UserModel: Equatable, Identifiable, @unchecked Sendable {
		@Attribute(.unique)
		public let id: String

		@Attribute(.unique)
		public var username: String

		public var password: Data
		public var displayName: String
		public var bio: String
		public var avatarURL: URL?

		@Relationship(deleteRule: .cascade)
		public var tweets: [TweetModel]

		@Relationship
		public var likedTweets: [TweetModel]

		@Relationship(inverse: \UserModel.followers)
		public var follows: [UserModel]

		@Relationship
		public var followers: [UserModel]

		public init(
			id: USID,
			username: String,
			password: Data,
			displayName: String = "",
			bio: String = "",
			avatarURL: URL? = nil,
			tweets: [TweetModel] = [],
			likedTweets: [TweetModel] = [],
			follows: [UserModel] = [],
			followers: [UserModel] = []
		) {
			self.id = id.rawValue
			self.username = username
			self.password = password
			self.displayName = displayName
			self.bio = bio
			self.avatarURL = avatarURL
			self.tweets = tweets
			self.likedTweets = likedTweets
			self.follows = follows
			self.followers = followers
		}
	}
}



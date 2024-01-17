import _Dependencies

public struct APIClient {
	public init(
		auth: Auth,
		feed: Feed,
		tweet: Tweet,
		user: User
	) {
		self.auth = auth
		self.feed = feed
		self.tweet = tweet
		self.user = user
	}

	public var auth: Auth
	public var feed: Feed
	public var tweet: Tweet
	public var user: User
}

extension DependencyValues {
	public var apiClient: APIClient {
		get { self[APIClient.self] }
		set { self[APIClient.self] = newValue }
	}
}

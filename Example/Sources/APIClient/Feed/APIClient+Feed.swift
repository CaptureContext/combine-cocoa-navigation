import LocalExtensions
import AppModels

extension APIClient {
	public struct Feed {
		public init(fetchTweets: Operations.FetchTweets) {
			self.fetchTweets = fetchTweets
		}

		public var fetchTweets: Operations.FetchTweets
	}
}

extension APIClient.Feed {
	public enum Operations {}
}

extension APIClient.Feed.Operations {
	public struct FetchTweets {
		public typealias Input = (
			page: Int,
			limit: Int
		)

		public typealias Output = Result<[TweetModel], APIClient.Error>

		public typealias AsyncSignature = @Sendable (Input) async -> Output

		public var asyncCall: AsyncSignature

		public init(_ asyncCall: @escaping AsyncSignature) {
			self.asyncCall = asyncCall
		}

		public func callAsFunction(
			page: Int = 0,
			limit: Int = 15
		) async -> Output {
			await asyncCall((page, limit))
		}
	}
}

import LocalExtensions
import AppModels

extension APIClient {
	public struct User {
		public init(
			fetch: Operations.Fetch,
			follow: Operations.Follow,
			report: Operations.Report,
			fetchTweets: Operations.FetchTweets
		) {
			self.fetch = fetch
			self.follow = follow
			self.report = report
			self.fetchTweets = fetchTweets
		}

		public var fetch: Operations.Fetch
		public var follow: Operations.Follow
		public var report: Operations.Report
		public var fetchTweets: Operations.FetchTweets
	}
}

extension APIClient.User {
	public enum Operations {}
}

extension APIClient.User.Operations {
	public struct Fetch {
		public typealias Input = USID

		public typealias Output = Result<UserInfoModel, Error>

		public typealias AsyncSignature = @Sendable (Input) async -> Output

		public var asyncCall: AsyncSignature

		public init(_ asyncCall: @escaping AsyncSignature) {
			self.asyncCall = asyncCall
		}

		public func callAsFunction(
			id: USID
		) async -> Output {
			await asyncCall(id)
		}
	}

	public struct Follow {
		public typealias Input = (
			id: USID,
			value: Bool
		)

		public typealias Output = Result<Void, Error>

		public typealias AsyncSignature = @Sendable (Input) async -> Output

		public var asyncCall: AsyncSignature

		public init(_ asyncCall: @escaping AsyncSignature) {
			self.asyncCall = asyncCall
		}

		public func callAsFunction(
			id: USID,
			value: Bool
		) async -> Output {
			await asyncCall((id, value))
		}
	}

	public struct Report {
		public typealias Input = USID

		public typealias Output = Result<Void, Error>

		public typealias AsyncSignature = @Sendable (Input) async -> Output

		public var asyncCall: AsyncSignature

		public init(_ asyncCall: @escaping AsyncSignature) {
			self.asyncCall = asyncCall
		}

		public func callAsFunction(
			id: USID
		) async -> Output {
			await asyncCall(id)
		}
	}

	public struct FetchTweets {
		public typealias Input = (
			id: USID,
			page: Int,
			limit: Int
		)

		public typealias Output = Result<[TweetModel], Error>

		public typealias AsyncSignature = @Sendable (Input) async -> Output

		public var asyncCall: AsyncSignature

		public init(_ asyncCall: @escaping AsyncSignature) {
			self.asyncCall = asyncCall
		}

		public func callAsFunction(
			for id: USID,
			page: Int = 0,
			limit: Int = 15
		) async -> Output {
			await asyncCall((id, page, limit))
		}
	}
}

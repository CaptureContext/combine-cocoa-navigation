import LocalExtensions
import AppModels

extension APIClient {
	public struct Tweet {
		public init(
			fetch: Operations.Fetch,
			like: Operations.Like,
			post: Operations.Post,
			repost: Operations.Repost,
			reply: Operations.Reply,
			delete: Operations.Delete,
			report: Operations.Report,
			fetchReplies: Operations.FetchReplies
		) {
			self.fetch = fetch
			self.like = like
			self.post = post
			self.repost = repost
			self.reply = reply
			self.delete = delete
			self.report = report
			self.fetchReplies = fetchReplies
		}

		public var fetch: Operations.Fetch
		public var like: Operations.Like
		public var post: Operations.Post
		public var repost: Operations.Repost
		public var reply: Operations.Reply
		public var delete: Operations.Delete
		public var report: Operations.Report
		public var fetchReplies: Operations.FetchReplies
	}
}

extension APIClient.Tweet {
	public enum Operations {}
}

extension APIClient.Tweet.Operations {
	public struct Fetch {
		public typealias Input = USID

		public typealias Output = Result<TweetModel, APIClient.Error>

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

	public struct Like {
		public typealias Input = (
			id: USID,
			value: Bool
		)

		public typealias Output = Result<Void, APIClient.Error>

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

	public struct Repost {
		public typealias Input = (
			id: USID,
			content: String
		)

		public typealias Output = Result<Void, APIClient.Error>

		public typealias AsyncSignature = @Sendable (Input) async -> Output

		public var asyncCall: AsyncSignature

		public init(_ asyncCall: @escaping AsyncSignature) {
			self.asyncCall = asyncCall
		}

		public func callAsFunction(
			id: USID,
			with content: String
		) async -> Output {
			await asyncCall((id, content))
		}
	}

	public struct Delete {
		public typealias Input = USID

		public typealias Output = Result<Void, APIClient.Error>

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

	public struct Report {
		public typealias Input = USID

		public typealias Output = Result<Void, APIClient.Error>

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

	public struct Reply {
		public typealias Input = (
			id: USID,
			content: String
		)

		public typealias Output = Result<Void, APIClient.Error>

		public typealias AsyncSignature = @Sendable (Input) async -> Output

		public var asyncCall: AsyncSignature

		public init(_ asyncCall: @escaping AsyncSignature) {
			self.asyncCall = asyncCall
		}

		public func callAsFunction(
			to id: USID,
			with content: String
		) async -> Output {
			await asyncCall((id, content))
		}
	}

	public struct Post {
		public typealias Input = String

		public typealias Output = Result<Void, APIClient.Error>

		public typealias AsyncSignature = @Sendable (Input) async -> Output

		public var asyncCall: AsyncSignature

		public init(_ asyncCall: @escaping AsyncSignature) {
			self.asyncCall = asyncCall
		}

		public func callAsFunction(
			_ text: String
		) async -> Output {
			await asyncCall(text)
		}
	}

	public struct FetchReplies {
		public typealias Input = (
			id: USID,
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
			for id: USID,
			page: Int = 0,
			limit: Int = 15
		) async -> Output {
			await asyncCall((id, page, limit))
		}
	}
}

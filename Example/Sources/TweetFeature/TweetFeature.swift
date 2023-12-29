import _ComposableArchitecture
import LocalExtensions
import AppModels

@Reducer
public struct TweetFeature {
	public init() {}

	@ObservableState
	public struct State: Equatable, Identifiable {
		@ObservableState
		public struct AuthorState: Equatable {
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
		public var replyTo: USID?
		public var repliesCount: Int
		public var isLiked: Bool
		public var likesCount: Int
		public var isReposted: Bool
		public var repostsCount: Int
		public var author: AuthorState
		public var text: String

		public init(
			id: USID,
			replyTo: USID? = nil,
			repliesCount: Int = 0,
			isLiked: Bool = false,
			likesCount: Int = 0,
			isReposted: Bool = false,
			repostsCount: Int = 0,
			author: AuthorState,
			text: String
		) {
			self.id = id
			self.replyTo = replyTo
			self.repliesCount = repliesCount
			self.isLiked = isLiked
			self.likesCount = likesCount
			self.isReposted = isReposted
			self.repostsCount = repostsCount
			self.author = author
			self.text = text
		}
	}

	public enum Action: Equatable {
		case tap
		case tapOnAuthor
		case openDetail(for: USID)
		case openProfile(USID)
	}

	public func reduce(
		into state: inout State,
		action: Action
	) -> Effect<Action> {
		switch action {
		case .tap:
			return .send(.openDetail(for: state.id))

		case .tapOnAuthor:
			return.send(.openProfile(state.author.id))

		default:
			return .none
		}
	}
}

extension Convertion where From == TweetModel, To == TweetFeature.State {
	public static var tweetFeature: Convertion {
		return .init { .init(
			id: $0.id,
			replyTo: $0.replyTo,
			repliesCount: $0.repliesCount,
			isLiked: $0.isLiked,
			likesCount: $0.likesCount,
			isReposted: $0.isReposted,
			repostsCount: $0.repostsCount,
			author: $0.author.convert(to: .tweetFeature),
			text: $0.text
		)}
	}
}

extension Convertion where From == TweetModel.AuthorModel, To == TweetFeature.State.AuthorState {
	public static var tweetFeature: Convertion {
		return .init { .init(
			id: $0.id,
			avatarURL: $0.avatarURL,
			username: $0.username
		)}
	}
}

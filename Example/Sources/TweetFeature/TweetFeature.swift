import _ComposableArchitecture
import LocalExtensions
import AppModels
import APIClient

@Reducer
public struct TweetFeature {
	public init() {}

	@ObservableState
	public struct State: Equatable, Identifiable {
		@ObservableState
		public struct AuthorState: Equatable {
			public var id: USID
			public var avatarURL: URL?
			public var displayName: String
			public var username: String

			public init(
				id: USID,
				avatarURL: URL? = nil,
				displayName: String = "",
				username: String
			) {
				self.id = id
				self.avatarURL = avatarURL
				self.displayName = displayName
				self.username = username
			}
		}

		public var id: USID
		public var createdAt: Date
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
			createdAt: Date = .now,
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
			self.createdAt = createdAt
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

	@CasePathable
	public enum Action: Equatable, BindableAction {
		case tap
		case tapOnAuthor
		case reply, toggleLike, repost, share
		case binding(BindingAction<State>)
	}

	@Dependency(\.apiClient)
	var apiClient

	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			#warning("Cancel pending effects as needed")
			switch action {
			case .reply:
				return .none
			case .toggleLike:
				let id = state.id
				let newIsLiked = !state.isLiked
				let oldLikesCount = state.likesCount

				state.isLiked = newIsLiked
				state.likesCount += newIsLiked ? 1 : -1

				return .run { send in
					do { try await apiClient.tweet.like(id: id, value: newIsLiked).get() }
					catch {
						await send(.binding(.set(\.isLiked, !newIsLiked)))
						await send(.binding(.set(\.likesCount, oldLikesCount)))
					}
				}
			case .repost:
				return .none

			case .share:
				return .none

			default:
				return .none
			}
		}
		BindingReducer()
	}
}

extension Convertion where From == TweetModel, To == TweetFeature.State {
	public static var tweetFeature: Convertion {
		return .init { .init(
			id: $0.id,
			createdAt: $0.createdAt,
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
			displayName: $0.displayName,
			username: $0.username
		)}
	}
}

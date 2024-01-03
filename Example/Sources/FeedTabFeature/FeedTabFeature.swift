import _ComposableArchitecture
import UserProfileFeature
import TweetsFeedFeature
import LocalExtensions
import ProfileAndFeedPivot
import TweetPostFeature
import TweetReplyFeature

@Reducer
public struct FeedTabFeature {
	public init() {}

	public typealias Path = ProfileAndFeedPivot

	@ObservableState
	public struct State: Equatable {
		public var feed: TweetsFeedFeature.State
		
		@Presents
		public var postTweet: TweetPostFeature.State?

		public var path: StackState<Path.State>

		public init(
			feed: TweetsFeedFeature.State = .init(),
			postTweet: TweetPostFeature.State? = nil,
			path: StackState<Path.State> = .init()
		) {
			self.feed = feed
			self.postTweet = postTweet
			self.path = path
		}
	}

	@CasePathable
	public enum Action: Equatable {
		case feed(TweetsFeedFeature.Action)
		case postTweet(PresentationAction<TweetPostFeature.Action>)
		case path(StackAction<Path.State, Path.Action>)
		case tweet
	}

	public var body: some ReducerOf<Self> {
		CombineReducers {
			Pullback(\.tweet) { state in
				state.postTweet = .init()
				return .none
			}

			Pullback(\.postTweet.event.didPostTweet.success) { state, _ in
				return .concatenate(
					.send(.postTweet(.dismiss)),
					.send(.feed(.fetchMoreTweets(reset: true)))
				)
			}

			Scope(
				state: \.feed,
				action: \.feed,
				child: TweetsFeedFeature.init
			)

			Reduce { state, action in
				switch action {
				case
					let .feed(.delegate(.openProfile(id))),
					let .path(.element(_, .delegate(.openProfile(id)))):
					state.path.append(.profile(.loading(id)))
					return .none

				default:
					return .none
				}
			}
			.forEach(
				\State.path,
				 action: \.path,
				 destination: Path.init
			)
			.ifLet(
				\.$postTweet,
				action: \.postTweet,
				destination: TweetPostFeature.init
			)
		}
	}
}

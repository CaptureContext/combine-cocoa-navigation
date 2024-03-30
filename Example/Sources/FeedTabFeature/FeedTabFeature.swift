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

    public var isFeedButtonVisible: Bool

		@Presents
		public var postTweet: TweetPostFeature.State?

		public var path: StackState<Path.State>

		public init(
			feed: TweetsFeedFeature.State = .init(dataSource: .common),
      isFeedButtonVisible: Bool = false,
			postTweet: TweetPostFeature.State? = nil,
			path: StackState<Path.State> = .init()
		) {
			self.feed = feed
      self.isFeedButtonVisible = isFeedButtonVisible
			self.postTweet = postTweet
			self.path = path
		}
	}

	@CasePathable
	public enum Action: Equatable {
		case feed(TweetsFeedFeature.Action)
		case postTweet(PresentationAction<TweetPostFeature.Action>)
		case path(StackAction<Path.State, Path.Action>)
    case event(Event)
		case tweet

    @CasePathable
    public enum Event: Equatable {
      case didAppear
      case didChangeUserID(USID?)
    }
	}

  @Dependency(\.currentUser)
  var currentUser

  @Dependency(\.mainQueue)
  var mainQueue

	public var body: some ReducerOf<Self> {
		CombineReducers {
      Pullback(\.event.didAppear) { state in
        struct CancellationID: Hashable {}
        let cancellationID = CancellationID()
        return .concatenate(
          .cancel(id: cancellationID),
          .publisher {
            currentUser.idPublisher
              .receive(on: mainQueue)
              .map(Action.Event.didChangeUserID)
              .map(Action.event)
          }
          .cancellable(id: cancellationID)
        )
      }
      Pullback(\.event.didChangeUserID) { state, id in
        state.isFeedButtonVisible = id.isNotNil
        return .none
      }

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

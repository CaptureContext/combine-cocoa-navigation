import _ComposableArchitecture
import UserProfileFeature
import TweetsFeedFeature

@Reducer
public struct FeedTabFeature {
	public init() {}

	@Reducer
	public struct Path {
		public enum State: Equatable {
			case feed(TweetsFeedFeature.State)
			case profile(UserProfileFeature.State)
		}

		public enum Action: Equatable {
			case feed(TweetsFeedFeature.Action)
			case profile(UserProfileFeature.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(
				state: /State.feed,
				action: /Action.feed,
				child: TweetsFeedFeature.init
			)
			Scope(
				state: /State.profile,
				action: /Action.profile,
				child: UserProfileFeature.init
			)
		}
	}

	@ObservableState
	public struct State: Equatable {
		public var feed: TweetsFeedFeature.State
		public var path: StackState<Path.State>

		public init(
			feed: TweetsFeedFeature.State = .init(),
			path: StackState<Path.State> = .init()
		) {
			self.feed = feed
			self.path = path
		}
	}

	public enum Action: Equatable {
		case feed(TweetsFeedFeature.Action)
		case path(StackAction<Path.State, Path.Action>)
	}

	public var body: some ReducerOf<Self> {
		CombineReducers {
			Scope(
				state: \.feed,
				action: \.feed,
				child: TweetsFeedFeature.init
			)
			Reduce { state, action in
				switch action {
				case 
					let .feed(.openProfile(id)),
					let .path(.element(_, action: .feed(.openProfile(id)))):
					state.path.append(.profile(.external(.init(model: .init(
						id: id,
						username: "\(id)"
					)))))
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
		}
	}
}

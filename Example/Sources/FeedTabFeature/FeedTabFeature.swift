import _ComposableArchitecture
import UserProfileFeature
import TweetsFeedFeature
import LocalExtensions

@Reducer
public struct FeedTabFeature {
	public init() {}

	@Reducer
	public struct Path {
		public enum State: Equatable {
			case feed(TweetsFeedFeature.State)
			case profile(UserProfileFeature.State)
		}

		@CasePathable
		public enum Action: Equatable {
			case feed(TweetsFeedFeature.Action)
			case profile(UserProfileFeature.Action)
			case delegate(Delegate)

			@CasePathable
			public enum Delegate: Equatable {
				case openProfile(USID)
			}
		}

		public var body: some ReducerOf<Self> {
			Reduce { state, action in
				switch action {
				case
					let .feed(.delegate(.openProfile(id))),
					let .profile(.delegate(.openProfile(id))):
					return .send(.delegate(.openProfile(id)))

				default:
					return .none
				}
			}
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

	@CasePathable
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
					let .feed(.delegate(.openProfile(id))),
					let .path(.element(_, action: .delegate(.openProfile(id)))):
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

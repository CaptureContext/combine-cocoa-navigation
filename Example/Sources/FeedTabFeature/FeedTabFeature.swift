import _ComposableArchitecture
import ProfileFeature
import TweetsFeedFeature

@Reducer
public struct FeedTabFeature {
	public init() {}

	@Reducer
	public struct Path {
		public enum State: Equatable {
			case feed(TweetsFeedFeature.State)
			case profile(ProfileFeature.State)
		}

		public enum Action: Equatable {
			case feed(TweetsFeedFeature.Action)
			case profile(ProfileFeature.Action)
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
				child: ProfileFeature.init
			)
		}
	}

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
					state.path.append(.profile(.user(.init(model: .mock(user: .mock(id: id))))))
					return .none

				case let .path(.element(stackID, action: .profile(profile))):
					switch profile {
					case .user(.tweetsList(.tweets(.element(_, .tap)))):
						guard case let .profile(.user(profile)) = state.path[id: stackID]
						else { return .none }
						state.path.append(.feed(.init(list: profile.tweetsList)))
						return .none

					case .currentUser(.tweetsList(.tweets(.element(_, .tap)))):
						guard case let .profile(.currentUser(profile)) = state.path[id: stackID]
						else { return .none }
						state.path.append(.feed(.init(list: profile.tweetsList)))
						return .none

					default:
						return .none
					}

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

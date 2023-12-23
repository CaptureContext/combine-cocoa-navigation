import _ComposableArchitecture

@Reducer
public struct ProfileTabFeature {
	public init() {}

	@Reducer
	public struct Path: Reducer {
		@ObservableState
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
		public var path: StackState<Path.State>

		public init(
			root: UserProfileFeature.State,
			path: StackState<Path.State> = .init()
		) {
			self.path = [.profile(root)] + path
		}
	}

	@CasePathable
	public enum Action: Equatable {
		case path(StackAction<Path.State, Path.Action>)
	}

	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case let .path(.element(_, action: .feed(.openProfile(id)))):
				state.path.append(.profile(.init(model: .mock(user: .mock(id: id)))))
				return .none

			case let .path(.element(stackID, .profile(.tweetsList(.tweets(.element(_, .tap)))))):
				guard case let .profile(profile) = state.path[id: stackID]
				else { return .none }

				state.path.append(.feed(.init(list: profile.tweetsList)))
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

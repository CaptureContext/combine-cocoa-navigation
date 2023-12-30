import _ComposableArchitecture
import AuthFeature
import ProfileAndFeedPivot
import UserProfileFeature
import TweetsFeedFeature
import CurrentUserProfileFeature

@Reducer
public struct ProfileTabFeature {
	public init() {}

	public typealias Path = ProfileAndFeedPivot

	@Reducer
	public struct Root {
		@ObservableState
		public enum State: Equatable {
			case auth(AuthFeature.State = .signIn())
			case profile(CurrentUserProfileFeature.State)
		}

		@CasePathable
		public enum Action: Equatable {
			case auth(AuthFeature.Action)
			case profile(CurrentUserProfileFeature.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(
				state: /State.auth,
				action: /Action.auth,
				child: AuthFeature.init
			)
			Scope(
				state: /State.profile,
				action: /Action.profile,
				child: CurrentUserProfileFeature.init
			)
		}
	}

	@ObservableState
	public struct State: Equatable {
		public var root: Root.State
		public var path: StackState<Path.State>

		public init(
			root: Root.State = .auth(),
			path: StackState<Path.State> = .init()
		) {
			self.root = root
			self.path = path
		}
	}

	@CasePathable
	public enum Action: Equatable {
		case path(StackAction<Path.State, Path.Action>)
	}

	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case let .path(.element(_, action: .feed(.delegate(.openProfile(id))))):
				state.path.append(.profile(.external(.init(model: .init(
					 id: id,
					 username: "\(id)"
				 )))))
				return .none

//			case let .path(.element(stackID, .profile(.user(.tweetsList(.tweets(.element(_, .tap))))))):
//				guard case let .profile(.external(profile)) = state.path[id: stackID]
//				else { return .none }
//
//				state.path.append(.feed(.init(list: profile.tweetsList)))
//				return .none

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

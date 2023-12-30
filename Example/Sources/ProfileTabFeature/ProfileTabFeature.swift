import _ComposableArchitecture
import AuthFeature
import ProfileAndFeedPivot
import UserProfileFeature
import TweetsFeedFeature
import CurrentUserProfileFeature
import LocalExtensions

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
			case setState(State)
		}

		public var body: some ReducerOf<Self> {
			Pullback(\.setState) { state, newState in
				state = newState
				return .none
			}
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
		case root(Root.Action)
		case path(StackAction<Path.State, Path.Action>)
		case event(Event)

		@CasePathable
		public enum Event: Equatable {
			case didAppear
			case didChangeUserID(USID?)
		}
	}

	@Dependency(\.currentUser)
	var currentUser

	@Dependency(\.apiClient)
	var apiClient

	public var body: some ReducerOf<Self> {
		Pullback(\.event.didAppear) { state in
			return .publisher {
				currentUser.idPublisher
					.map(Action.Event.didChangeUserID)
					.map(Action.event)
			}
		}
		Pullback(\.event.didChangeUserID) { state, id in
			guard let id else {
				return .send(.root(.setState(.auth(.signIn()))))
			}

			return .run { send in
				switch await apiClient.user.fetch(id: id) {
				case let .success(user):
					await send(.root(.setState(.profile(.init(model: user)))))

				case let .failure(error):
					#warning("Handle error with alert")
					await send(.root(.setState(.auth(.signIn()))))
				}
			}
		}
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
		Scope(
			state: \.root,
			action: \.root,
			child: Root.init
		)
	}
}

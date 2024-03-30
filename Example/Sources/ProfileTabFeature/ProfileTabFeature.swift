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

  @Dependency(\.mainQueue)
  var mainQueue

	public var body: some ReducerOf<Self> {
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
		Pullback(\.event.didChangeUserID) { (state: inout State, id: USID?) in
			guard let id else {
				state.path.removeAll()
				return .send(.root(.setState(.auth(.signIn(.init(username: "capturecontext", password: "psswrd"))))))
			}

			// no changes
			if state.root.profile?.model.id == id { return .none }

			return .run { send in
				switch await apiClient.user.fetch(id: id) {
				case let .success(user):
					await send(.root(.setState(.profile(.init(model: user)))))

				case let .failure(error):
					#warning("Handle error with alert")
          await send(.root(.setState(.auth(.signIn(.init(username: "capturecontext", password: "psswrd"))))))
				}
			}
		}
		Reduce { state, action in
			switch action {
			case
				let .root(.profile(.delegate(.openProfile(id)))),
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
		Scope(
			state: \.root,
			action: \.root,
			child: Root.init
		)
	}
}

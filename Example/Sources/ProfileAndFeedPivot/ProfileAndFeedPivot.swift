import _ComposableArchitecture
import TweetsFeedFeature
import UserProfileFeature
import LocalExtensions

@Reducer
public struct ProfileAndFeedPivot {
	@ObservableState
	public enum State: Equatable {
		case feed(TweetsFeedFeature.State = .init())
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

	public init() {}

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

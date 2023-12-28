import _ComposableArchitecture
import TweetsFeedFeature
import UserProfileFeature

@Reducer
public struct ProfileAndFeedPivot {
	@ObservableState
	public enum State: Equatable {
		case feed(TweetsFeedFeature.State = .init())
		case profile(UserProfileFeature.State)
	}

	public enum Action: Equatable {
		case feed(TweetsFeedFeature.Action)
		case profile(UserProfileFeature.Action)
	}

	public init() {}

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

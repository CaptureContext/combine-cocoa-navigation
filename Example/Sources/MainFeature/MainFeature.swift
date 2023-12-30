import _ComposableArchitecture
import FeedTabFeature
import ProfileTabFeature

@Reducer
public struct MainFeature {
	@ObservableState
	public struct State: Equatable {
		public init(
			feed: FeedTabFeature.State = .init(),
			profile: ProfileTabFeature.State = .init(),
			selectedTab: Tab = .feed
		) {
			self.feed = feed
			self.profile = profile
			self.selectedTab = selectedTab
		}

		public var feed: FeedTabFeature.State
		public var profile: ProfileTabFeature.State
		public var selectedTab: Tab

		@CasePathable
		public enum Tab: Hashable {
			case feed
			case profile
		}
	}

	public enum Action: Equatable, BindableAction {
		case feed(FeedTabFeature.Action)
		case profile(ProfileTabFeature.Action)
		case binding(BindingAction<State>)
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(
			state: \.feed,
			action: \.feed,
			child: FeedTabFeature.init
		)
		Scope(
			state: \.profile,
			action: \.profile,
			child: ProfileTabFeature.init
		)
		BindingReducer()
	}
}

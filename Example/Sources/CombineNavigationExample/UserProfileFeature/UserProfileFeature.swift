import ComposableArchitecture
import FoundationExtensions

public struct UserProfileFeature: Reducer {
	public init() {}

	public struct State: Equatable {
		public var model: FollowerModel
		public var tweets: TweetsListFeature.State

		@PresentationState
		public var avatarPreview: URL?

		public init(
			model: FollowerModel,
			tweets: TweetsListFeature.State = .init()
		) {
			self.model = model
			self.tweets = tweets
		}
	}

	@CasePathable
	public enum Action: Equatable {
		case avatarPreview(PresentationAction<Never>)
		case tweetsList(TweetsListFeature.Action)
		case openDetail(for: UUID)
		case openProfile(UUID)
		case tapOnAvatar
		case tapFollow
	}

	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case .tapOnAvatar:
				state.avatarPreview = state.model.user.avatarURL
				return .none

			case .tapFollow:
				state.model.isFollowedByYou.toggle()
				return .none

			case let .tweetsList(.tweets(.element(_, .openDetail(id)))):
				return .send(.openDetail(for: id))

			case let .tweetsList(.tweets(.element(_, .openProfile(id)))):
				return .send(.openProfile(id))

			default:
				return .none
			}
		}
		.ifLet(
			\State.$avatarPreview,
			 action: \.avatarPreview,
			 destination: {}
		)
		Scope(
			state: \.tweets,
			action: \.tweetsList,
			child: TweetsListFeature.init
		)
	}
}

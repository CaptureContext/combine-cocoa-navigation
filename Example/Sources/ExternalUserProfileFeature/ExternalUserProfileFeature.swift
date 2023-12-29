import _ComposableArchitecture
import LocalExtensions
import AppModels
import TweetsListFeature

@Reducer
public struct ExternalUserProfileFeature {
	public init() {}

	@ObservableState
	public struct State: Equatable {
		public var model: UserInfoModel
		public var tweetsList: TweetsListFeature.State

		@Presents
		public var avatarPreview: URL?

		public init(
			model: UserInfoModel,
			tweetsList: TweetsListFeature.State = .init()
		) {
			self.model = model
			self.tweetsList = tweetsList
		}
	}

	public enum Action: Equatable {
		case avatarPreview(PresentationAction<Never>)
		case tweetsList(TweetsListFeature.Action)
		case openDetail(for: USID)
		case openProfile(USID)
		case tapOnAvatar
		case tapFollow
	}

	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case .tapOnAvatar:
				state.avatarPreview = state.model.avatarURL
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
			state: \.tweetsList,
			action: \.tweetsList,
			child: TweetsListFeature.init
		)
	}
}

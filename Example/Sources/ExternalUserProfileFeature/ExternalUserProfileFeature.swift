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

	@CasePathable
	public enum Action: Equatable {
		case avatarPreview(PresentationAction<Never>)
		case tweetsList(TweetsListFeature.Action)
		case tapOnAvatar
		case tapFollow
		case delegate(Delegate)

		@CasePathable
		public enum Delegate: Equatable {
			case openDetail(USID)
			case openProfile(USID)
		}
	}

	public var body: some ReducerOf<Self> {
		CombineReducers {
			Reduce { state, action in
				switch action {
				case .tapOnAvatar:
					state.avatarPreview = state.model.avatarURL
					return .none

				case .tapFollow:
					state.model.isFollowedByYou.toggle()
					return .none

				default:
					return .none
				}
			}
			Reduce { state, action in
				switch action {
				case let .tweetsList(.delegate(.openDetail(id))):
					return .send(.delegate(.openDetail(id)))

				case let .tweetsList(.delegate(.openProfile(id))):
					guard id != state.model.id else { return .none }
					return .send(.delegate(.openProfile(id)))

				default:
					return .none
				}
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

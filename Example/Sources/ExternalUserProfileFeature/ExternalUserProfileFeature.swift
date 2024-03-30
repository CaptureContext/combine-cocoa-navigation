import _ComposableArchitecture
import LocalExtensions
import AppModels
import TweetsFeedFeature
import UserSettingsFeature

@Reducer
public struct ExternalUserProfileFeature {
	public init() {}

	@ObservableState
	public struct State: Equatable {
		public var model: UserInfoModel

		public var feed: TweetsFeedFeature.State

		@Presents
		public var presentationDestination: PresentationDestination.State?

		public init(
			model: UserInfoModel,
			feed: TweetsFeedFeature.State = .init(),
			presentationDestination: PresentationDestination.State? = nil
		) {
			self.model = model
			self.feed = feed
			self.presentationDestination = presentationDestination

			do { // additional setup
				self.feed.dataSource = .user(model.id)
			}
		}
	}

	@CasePathable
	public enum Action: Equatable {
		case tapFollow
		case feed(TweetsFeedFeature.Action)
		case presentationDestination(PresentationAction<PresentationDestination.Action>)
		case tapOnAvatar
		case delegate(Delegate)

		@CasePathable
		public enum Delegate: Equatable {
			case openProfile(USID)
		}
	}

	@inlinable
	public var body: some ReducerOf<Self> {
		CombineReducers {
			Reduce { state, action in
				switch action {
				case .tapOnAvatar:
					guard let avatarURL = state.model.avatarURL
					else { return .none}
					state.presentationDestination = .avatarPreivew(avatarURL)
					return .none

				case .tapFollow:
					state.model.isFollowedByYou.toggle()
					return .none

				default:
					return .none
				}
			}

			Pullback(\.feed.delegate.openProfile) { state, id in
				guard id != state.model.id else { return .none }
				return .send(.delegate(.openProfile(id)))
			}

			Scope(
				state: \.feed,
				action: \.feed,
				child: TweetsFeedFeature.init
			)
		}
		.ifLet(
			\.$presentationDestination,
			action: \.presentationDestination,
			destination: PresentationDestination.init
		)
	}
}

extension ExternalUserProfileFeature {
	@Reducer
	public struct PresentationDestination {
		public init() {}

		@ObservableState
		public enum State: Equatable {
			case avatarPreivew(URL)
			case userSettings(UserSettingsFeature.State)
		}

		@CasePathable
		public enum Action: Equatable {
			case avatarPreivew(Never)
			case userSettings(UserSettingsFeature.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(
				state: \.userSettings,
				action: \.userSettings,
				child: UserSettingsFeature.init
			)
		}
	}
}

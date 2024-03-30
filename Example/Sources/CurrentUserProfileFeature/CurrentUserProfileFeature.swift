import _ComposableArchitecture
import LocalExtensions
import AppModels
import TweetsFeedFeature
import UserSettingsFeature

@Reducer
public struct CurrentUserProfileFeature {
	public init() {}

	@ObservableState
	public struct State: Equatable {
		public var model: UserInfoModel

		public var feed: TweetsFeedFeature.State

		@Presents
		public var presentationDestination: PresentationDestination.State?

		@Presents
		public var navigationDestination: NavigationDestination.State?

		public init(
			model: UserInfoModel,
			feed: TweetsFeedFeature.State = .init(),
			presentationDestination: PresentationDestination.State? = nil,
			navigationDestination: NavigationDestination.State? = nil
		) {
			self.model = model
			self.feed = feed
			self.presentationDestination = presentationDestination
			self.navigationDestination = navigationDestination

			do { // additional setup
				self.feed.dataSource = .user(model.id)
			}
		}
	}

	@CasePathable
	public enum Action: Equatable {
		case openSettings
		case feed(TweetsFeedFeature.Action)
		case presentationDestination(PresentationAction<PresentationDestination.Action>)
		case navigationDestination(PresentationAction<NavigationDestination.Action>)
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

				case .openSettings:
					state.navigationDestination = .userSettings(.init(id: state.model.id))
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
		.ifLet(
			\.$navigationDestination,
			action: \.navigationDestination,
			destination: NavigationDestination.init
		)
	}
}

extension CurrentUserProfileFeature {
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

	@Reducer
	public struct NavigationDestination {
		public init() {}

		@ObservableState
		public enum State: Equatable {
			case userSettings(UserSettingsFeature.State)
		}

		@CasePathable
		public enum Action: Equatable {
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

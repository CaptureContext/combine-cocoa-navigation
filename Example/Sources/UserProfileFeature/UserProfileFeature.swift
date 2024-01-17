import _ComposableArchitecture
import ExternalUserProfileFeature
import CurrentUserProfileFeature
import LocalExtensions
import AppModels
import APIClient

@Reducer
public struct UserProfileFeature {
	public init() {}

	@ObservableState
	@CasePathable
	public enum State: Equatable {
		case external(ExternalUserProfileFeature.State)
		case current(CurrentUserProfileFeature.State)
		case loading(USID)
	}

	@CasePathable
	public enum Action: Equatable {
		case external(ExternalUserProfileFeature.Action)
		case current(CurrentUserProfileFeature.Action)
		case event(Event)
		case delegate(Delegate)

		@CasePathable
		public enum Event: Equatable {
			case didAppear
			case didLoadProfile(Result<UserInfoModel, APIClient.Error>)
		}

		@CasePathable
		public enum Delegate: Equatable {
			case openProfile(USID)
		}
	}

	@Dependency(\.apiClient)
	var apiClient

	@Dependency(\.currentUser)
	var currentUser

	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case
				let .current(.delegate(.openProfile(id))),
				let .external(.delegate(.openProfile(id))):
				return .send(.delegate(.openProfile(id)))
				
			default:
				return .none
			}
		}

		Reduce { state, action in
			guard case let .loading(id) = state
			else { return .none }

			switch action {
			case .event(.didAppear):
				return .run { send in
					await send(.event(.didLoadProfile(
						apiClient.user.fetch(id: id)
					)))
				}

			case let .event(.didLoadProfile(result)):
				switch result {
				case let .success(profile):
					state = profile.id == currentUser.id
					 ? .current(.init(model: profile))
					 : .external(.init(model: profile))
					return .none
				case .failure:
					#warning("Handle error")
					return .none
				}

			default:
				return .none
			}
		}

		Scope(
			state: \.current,
			action: \.current,
			child: CurrentUserProfileFeature.init
		)

		Scope(
			state: \.external,
			action: \.external,
			child: ExternalUserProfileFeature.init
		)
	}
}

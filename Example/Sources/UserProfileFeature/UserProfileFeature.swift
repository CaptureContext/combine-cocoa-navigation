import _ComposableArchitecture
import ExternalUserProfileFeature
import CurrentUserProfileFeature
import LocalExtensions

@Reducer
public struct UserProfileFeature {
	public init() {}

	@ObservableState
	public enum State: Equatable {
		case external(ExternalUserProfileFeature.State)
		case current(CurrentUserProfileFeature.State)
	}

	@CasePathable
	public enum Action: Equatable {
		case external(ExternalUserProfileFeature.Action)
		case current(CurrentUserProfileFeature.Action)
		case delegate(Delegate)

		@CasePathable
		public enum Delegate: Equatable {
			case openProfile(USID)
		}
	}
	
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
		.ifCaseLet(
			\.external,
			 action: \.external,
			 then: ExternalUserProfileFeature.init
		)
		.ifCaseLet(
			\.current,
			 action: \.current,
			 then: CurrentUserProfileFeature.init
		)
	}
}

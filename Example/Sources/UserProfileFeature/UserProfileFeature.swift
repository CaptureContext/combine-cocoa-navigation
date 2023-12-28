import _ComposableArchitecture
import ExternalUserProfileFeature
import CurrentUserProfileFeature

@Reducer
public struct UserProfileFeature {
	public init() {}

	@ObservableState
	public enum State: Equatable {
		case external(ExternalUserProfileFeature.State)
		case current(CurrentUserProfileFeature.State)
	}

	public enum Action: Equatable {
		case external(ExternalUserProfileFeature.Action)
		case current(CurrentUserProfileFeature.Action)
	}

	public var body: some ReducerOf<Self> {
		EmptyReducer()
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

import _ComposableArchitecture

@Reducer
public struct ProfileFeature {
	public init() {}

	@ObservableState
	public enum State: Equatable {
		case user(UserProfileFeature.State)
		case currentUser(CurrentUserProfileFeature.State)
	}

	public enum Action: Equatable {
		case user(UserProfileFeature.Action)
		case currentUser(CurrentUserProfileFeature.Action)
	}

	public var body: some ReducerOf<Self> {
		EmptyReducer()
			.ifCaseLet(
				\.user,
				action: \.user,
				then: UserProfileFeature.init
			)
			.ifCaseLet(
				\.currentUser,
				action: \.currentUser,
				then: CurrentUserProfileFeature.init
			)
	}
}

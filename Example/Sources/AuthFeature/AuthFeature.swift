import _ComposableArchitecture

@Reducer
public struct AuthFeature {
	@ObservableState
	public enum State: Equatable {
		case signIn(SignIn.State = .init())
		case signUp(SignUp.State = .init())
	}

	public enum Action: Equatable {
		case signIn(SignIn.Action)
		case signUp(SignUp.Action)
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		CombineReducers {
			Scope(
				state: \.signIn,
				action: \.signIn,
				child: SignIn.init
			)
			Scope(
				state: \.signUp,
				action: \.signUp,
				child: SignUp.init
			)
		}
	}
}

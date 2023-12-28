import _ComposableArchitecture
import LocalExtensions
import APIClient

extension AuthFeature {
	@Reducer
	public struct SignIn {
		@ObservableState
		public struct State: Equatable {
			public init(
				username: String = "",
				password: String = ""
			) {
				self.username = username
				self.password = password
			}

			public var username: String
			public var password: String

			@Presents
			public var alert: AlertState<Action>?
		}

		public enum Action: Equatable, BindableAction {
			case signInButtonTapped
			case binding(BindingAction<State>)
			case event(Event)

			@CasePathable
			public enum Event: Equatable {
				case result(Result<Equated<Void>, Equated<Error>>)
			}
		}

		public init() {}

		@Dependency(\.apiClient)
		var apiClient

		public var body: some ReducerOf<Self> {
			CombineReducers {
				Pullback(\.signInButtonTapped) { state in
					let state = state
					return .run { send in
						switch await apiClient.auth.signIn(
							username: state.username,
							password: state.password
						) {
						case .success:
							await send(.event(.result(.success(.void))))
						case let .failure(error):
							await send(.event(.result(.failure(.init(error)))))
						}
					}
				}
				Pullback(\.event.result.failure) { state, error in
					return .send(.binding(.set(\.alert, AlertState(
						title: { TextState("Error") },
						actions: {
							ButtonState(
								role: .cancel,
								action: .binding(.set(\.alert, nil)),
								label: { TextState("OK") }
							)
						},
						message: { TextState(error.localizedDescription) }
					))))
				}
				BindingReducer()
			}
		}
	}
}

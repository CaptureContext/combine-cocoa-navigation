import _ComposableArchitecture
import LocalExtensions
import APIClient

@Reducer
public struct TweetPostFeature {
	public init() {}

	@ObservableState
	public struct State: Equatable {
		public var avatarURL: URL?
		public var text: String

		@Presents
		public var alert: AlertState<Action.Alert>?

		public init(
			avatarURL: URL? = nil,
			text: String = "",
			alert: AlertState<Action.Alert>? = nil
		) {
			self.avatarURL = avatarURL
			self.text = text
			self.alert = alert
		}
	}

	@CasePathable
	public enum Action: Equatable, BindableAction {
		case binding(BindingAction<State>)
		case tweet
		case alert(Alert)
		case event(Event)

		@CasePathable
		public enum Alert: Equatable {
			case didTapAccept
			case didTapRecoveryOption(String)
		}

		@CasePathable
		public enum Event: Equatable {
			case didPostTweet(Result<Unit, APIClient.Error>)
		}
	}

	@Dependency(\.apiClient)
	var apiClient

	@Dependency(\.currentUser)
	var currentUser

	public var body: some ReducerOf<Self> {
		Pullback(\.tweet) { state in
			guard state.text.isNotEmpty else { return .none }
			let content = state.text
			return .run { send in
				let result = await apiClient.tweet.post(content)
				await send(.event(.didPostTweet(result.map(Unit.init))))
			}
		}

		Reduce { state, action in
			switch action {
			case let .event(.didPostTweet(.failure(error))):
				state.alert = makeAlert(for: error)
				return .none
			case .alert(.didTapAccept):
				state.alert = nil
				return .none

			case let .alert(.didTapRecoveryOption(deeplink)):
				#warning("TODO: Handle deeplink")
				return .none

			default:
				return .none
			}
		}

		BindingReducer()
	}

	func makeAlert(for error: APIClient.Error) -> AlertState<Action.Alert> {
		.init(
			title: {
				TextState(error.message)
			},
			actions: {
				ButtonState(role: .cancel, action: .send(.didTapAccept)) {
					TextState("OK")
				}
			}
		)
	}
}

public func injectTweetPost<State, Action: CasePathable>(
	on toPostAction: CaseKeyPath<Action, Void>,
	state toPresentationState: WritableKeyPath<State, PresentationState<TweetPostFeature.State>>,
	action toPresentationAction: CaseKeyPath<Action, PresentationAction<TweetPostFeature.Action>>,
	child: () -> TweetPostFeature
) -> some Reducer<State, Action> {
	CombineReducers {
		Pullback(toPostAction) { state in
			#warning("Use currentUser avatarURL")
			state[keyPath: toPresentationState].wrappedValue = .init()
			return .none
		}
		Pullback(toPresentationAction.appending(path: \.presented.event.didPostTweet.success)) { state, _ in
			return .send(toPresentationAction(.dismiss))
		}
	}
}

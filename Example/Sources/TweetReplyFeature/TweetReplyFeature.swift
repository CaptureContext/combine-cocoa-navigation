import _ComposableArchitecture
import TweetFeature
import LocalExtensions
import APIClient

@Reducer
public struct TweetReplyFeature {
	public init() {}

	@ObservableState
	public struct State: Equatable {
		public var source: TweetFeature.State
		public var avatarURL: URL?
		public var replyText: String
		
		@Presents
		public var alert: AlertState<Action.Alert>?

		public init(
			source: TweetFeature.State,
			avatarURL: URL? = nil,
			replyText: String = "",
			alert: AlertState<Action.Alert>? = nil
		) {
			self.source = source
			self.avatarURL = avatarURL
			self.replyText = replyText
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
			guard state.replyText.isNotEmpty else { return .none }
			let state = state
			return .run { send in
				let result = await apiClient.tweet.reply(
					to: state.source.id,
					with: state.replyText
				)

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

public func injectTweetReply<State, Action: CasePathable>(
	tweetsState toTweetsState: @escaping (State) -> IdentifiedArrayOf<TweetFeature.State>,
	tweetsAction toTweetsAction: CaseKeyPath<Action, IdentifiedActionOf<TweetFeature>>,
	state toPresentationState: WritableKeyPath<State, PresentationState<TweetReplyFeature.State>>,
	action toPresentationAction: CaseKeyPath<Action, PresentationAction<TweetReplyFeature.Action>>,
	child: () -> TweetReplyFeature
) -> some Reducer<State, Action> {
	CombineReducers {
		Pullback(toTweetsAction, action: \.reply) { state, id in
			guard let tweet = toTweetsState(state)[id: id]
			else { return .none }

			#warning("Use currentUser avatarURL")
			state[keyPath: toPresentationState].wrappedValue = .init(
				source: tweet,
				avatarURL: nil,
				replyText: "",
				alert: nil
			)

			return .none
		}
		Pullback(toPresentationAction.appending(
			path: \.presented.event.didPostTweet.success
		)) { state, _ in
			return .send(toPresentationAction(.dismiss))
		}
	}
}

public func injectTweetReply<State, Action: CasePathable>(
	tweetState toTweetState: @escaping (State) -> TweetFeature.State,
	tweetAction toTweetAction: CaseKeyPath<Action, TweetFeature.Action>,
	state toPresentationState: WritableKeyPath<State, PresentationState<TweetReplyFeature.State>>,
	action toPresentationAction: CaseKeyPath<Action, PresentationAction<TweetReplyFeature.Action>>,
	child: () -> TweetReplyFeature
) -> some Reducer<State, Action> {
	CombineReducers {
		Pullback(toTweetAction.appending(path: \.reply)) { state in
			 #warning("Use currentUser avatarURL")
			 state[keyPath: toPresentationState].wrappedValue = .init(
				 source: toTweetState(state),
				 avatarURL: nil,
				 replyText: "",
				 alert: nil
			 )
			 return .none
		 }
		 Pullback(toPresentationAction.appending(
			path: \.presented.event.didPostTweet.success
		 )) { state, _ in
			 return .send(toPresentationAction(.dismiss))
		 }
	}
}

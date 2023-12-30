import _ComposableArchitecture
import LocalExtensions
import APIClient
import TweetsListFeature
import TweetDetailFeature
import AppModels

@Reducer
public struct TweetsFeedFeature {
	public init() {}

	@ObservableState
	public struct State: Equatable {
		public var list: TweetsListFeature.State

		@Presents
		public var detail: TweetDetailFeature.State?

		@Presents
		public var alert: AlertState<Action.Alert>?

		public init(
			list:  TweetsListFeature.State = .init(),
			detail: TweetDetailFeature.State? = nil,
			alert: AlertState<Action.Alert>? = nil
		) {
			self.list = list
			self.detail = detail
		}
	}

	@CasePathable
	public enum Action: Equatable {
		case list(TweetsListFeature.Action)
		case detail(PresentationAction<TweetDetailFeature.Action>)
		case fetchMoreTweets
		case alert(Alert)
		case event(Event)
		case delegate(Delegate)

		@CasePathable
		public enum Alert: Equatable {
			case close
			case didTapRecoveryOption(String)
		}

		@CasePathable
		public enum Event: Equatable {
			case didAppear
			case didFetchTweets(Result<[TweetModel], APIClient.Error>)
		}

		@CasePathable
		public enum Delegate: Equatable {
			case openProfile(USID)
		}
	}

	@Dependency(\.apiClient)
	var apiClient

	public var body: some ReducerOf<Self> {
		CombineReducers {
			Reduce { state, action in
				switch action {
				case
					let .list(.delegate(.openProfile(id))),
					let .detail(.presented(.delegate(.openProfile(id)))):
					return .send(.delegate(.openProfile(id)))

				case let .list(.delegate(.openDetail(id))):
					guard let tweet = state.list.tweets[id: id] 
					else { return .none }

					state.detail = .init(source: tweet)
					return .none

				default:
					return .none
				}
			}

			Pullback(\.event.didAppear) { state in
				return .send(.fetchMoreTweets)
			}

			Reduce { state, action in
				switch action {
				case .fetchMoreTweets:
					let tweetsCount = state.list.tweets.count
					return .run { send in
						await send(.event(.didFetchTweets(
							apiClient.feed.fetchTweets(
								page: tweetsCount / 10,
								limit: 10
							)
						)))
					}
				case let .event(.didFetchTweets(tweets)):
					switch tweets {
					case let .success(tweets):
						let tweets = tweets.map { $0.convert(to: .tweetFeature) }
						state.list.tweets.append(contentsOf: tweets)
						return .none
						
					case let .failure(error):
						state.alert = makeAlert(for: error)
						return .none
					}

				default:
					return .none
				}
			}

			Reduce { state, action in
				switch action {
				case .alert(.close):
					state.alert = nil
					return .none

				case let .alert(.didTapRecoveryOption(deeplink)):
					#warning("TODO: Handle deeplink")
					return .none

				default:
					 return .none
				}
			}
		}
		.ifLet(
			\State.$detail,
			 action: \.detail,
			 destination: TweetDetailFeature.init
		)

		Scope(
			state: \State.list,
			action: \.list,
			child: TweetsListFeature.init
		)
	}

	func makeAlert(for error: APIClient.Error) -> AlertState<Action.Alert> {
		.init(
			title: {
				TextState(error.message)
			},
			actions: {
				ButtonState(role: .cancel, action: .send(.close)) {
					TextState("")
				}
			}
		)
	}
}

import _ComposableArchitecture
import LocalExtensions
import APIClient
import TweetsListFeature
import TweetReplyFeature
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
		public var tweetReply: TweetReplyFeature.State?

		@Presents
		public var alert: AlertState<Action.Alert>?

		public init(
			list: TweetsListFeature.State = .init(),
			detail: TweetDetailFeature.State? = nil,
			tweetReply: TweetReplyFeature.State? = nil,
			alert: AlertState<Action.Alert>? = nil
		) {
			self.list = list
			self.detail = detail
			self.tweetReply = tweetReply
			self.alert = alert
		}
	}

	@CasePathable
	public enum Action: Equatable {
		case list(TweetsListFeature.Action)
		case detail(PresentationAction<TweetDetailFeature.Action>)
		case tweetReply(PresentationAction<TweetReplyFeature.Action>)
		case fetchMoreTweets(reset: Bool = false)
		case alert(Alert)
		case event(Event)
		case delegate(Delegate)

		@CasePathable
		public enum Alert: Equatable {
			case didTapAccept
			case didTapRecoveryOption(String)
		}

		@CasePathable
		public enum Event: Equatable {
			case didAppear
			case didFetchTweets(Result<FetchedTweets, APIClient.Error>)

			public struct FetchedTweets: Equatable {
				public var tweets: [TweetModel]
				public var reset: Bool

				public init(
					tweets: [TweetModel],
					reset: Bool
				) {
					self.tweets = tweets
					self.reset = reset
				}
			}
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
				return .run { send in
					try await Task.sleep(nanoseconds: 1_000_000_000)
					await send(.fetchMoreTweets())
				}
			}

			Reduce { state, action in
				switch action {
				case let .fetchMoreTweets(reset):
					let tweetsCount = reset ? 0 : state.list.tweets.count
					return .run { send in
						await send(.event(.didFetchTweets(
							apiClient.feed.fetchTweets(
								page: tweetsCount / 10,
								limit: 10
							).map { tweets in
								Action.Event.FetchedTweets(
									tweets: tweets,
									reset: reset
								)
							}
						)))
					}
				case let .event(.didFetchTweets(tweets)):
					switch tweets {
					case let .success(fetched):
						let tweets = fetched.tweets.map { $0.convert(to: .tweetFeature) }
						if fetched.reset {
							state.list.tweets = .init(uniqueElements: tweets)
						} else {
							state.list.tweets.append(contentsOf: tweets)
						}
						state.list.placeholder = .text()
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

			Scope(
				state: \State.list,
				action: \.list,
				child: TweetsListFeature.init
			)

			injectTweetReply(
				tweetsState: \.list.tweets,
				tweetsAction: \.list.tweets,
				state: \.$tweetReply,
				action: \.tweetReply,
				child: TweetReplyFeature.init
			)
		}
		.ifLet(
			\.$tweetReply,
			action: \.tweetReply,
			destination: TweetReplyFeature.init
		)
		.ifLet(
			\State.$detail,
			action: \.detail,
			destination: TweetDetailFeature.init
		)
		.syncTweetDetailSource(
			state: \.$detail,
			with: \.list
		)
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

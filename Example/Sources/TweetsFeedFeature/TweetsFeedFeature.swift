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
		public var dataSource: DataSource?

		public var list: TweetsListFeature.State

		@Presents
		public var presentationDestination: PresentationDestination.State?

		@Presents
		public var navigationDestination: NavigationDestination.State?

		public init(
			dataSource: DataSource? = nil,
			list: TweetsListFeature.State = .init(),
			presentationDestination: PresentationDestination.State? = nil,
			navigationDestination: NavigationDestination.State? = nil
		) {
			self.dataSource = dataSource
			self.list = list
			self.presentationDestination = presentationDestination
			self.navigationDestination = navigationDestination
		}

		public enum DataSource: Equatable {
			case common
			case user(USID)
		}
	}

	@CasePathable
	public enum Action: Equatable {
		case list(TweetsListFeature.Action)
		case detail(PresentationAction<TweetDetailFeature.Action>)
		case fetchMoreTweets(reset: Bool = false)
		case presentationDestination(PresentationAction<PresentationDestination.Action>)
		case navigationDestination(PresentationAction<NavigationDestination.Action>)
		case event(Event)
		case delegate(Delegate)

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

	@inlinable
	public var body: some ReducerOf<Self> {
		CombineReducers {
			Reduce { state, action in
				switch action {
				case
					let .list(.delegate(.openProfile(id))),
					let .navigationDestination(.presented(.detail(.delegate(.openProfile(id))))):
					return .send(.delegate(.openProfile(id)))

				case let .list(.delegate(.openDetail(id))):
					guard let tweet = state.list.tweets[id: id]
					else { return .none }

					state.navigationDestination = .detail(.init(source: tweet))
					return .none

				default:
					return .none
				}
			}

			Pullback(\.event.didAppear) { state in
				return .run { send in
					await send(.fetchMoreTweets())
				}
			}

			fetchTweetsReducer
			syncTweetReplyReducer
			alertReducer

			Scope(
				state: \State.list,
				action: \.list,
				child: TweetsListFeature.init
			)
		}
		.ifLet(
			\.$presentationDestination,
			action: \.presentationDestination,
			destination: PresentationDestination.init
		)
		.ifLet(
			\.$navigationDestination,
			action: \.navigationDestination,
			destination: NavigationDestination.init
		)
		.syncTweetList(
			state: \.list,
			with: \.$navigationDestination.detail
		)
	}

	@usableFromInline
	var fetchTweetsReducer: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case let .fetchMoreTweets(reset):
				switch state.dataSource {
				case let .user(userID):
					let tweetsCount = reset ? 0 : state.list.tweets.count
					return .run { send in
						await send(.event(.didFetchTweets(
							apiClient.user.fetchTweets(
								for: userID,
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

				case .common:
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
				default:
					if reset { state.list.tweets.removeAll() }
					return .none
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
					state.presentationDestination = .alert(makeAlert(for: error))
					return .none
				}

			default:
				return .none
			}
		}
	}

	@usableFromInline
	var syncTweetReplyReducer: some ReducerOf<Self> {
		CombineReducers {
			Pullback(\.list.tweets, action: \.reply) { state, id in
				state.list.tweets[id: id].map { tweet in
					state.presentationDestination = .tweetReply(.init(source: tweet))
				}
				return .none
			}

			Pullback(\.presentationDestination.tweetReply.close) { state, _ in
				guard case .tweetReply = state.presentationDestination
				else { return .none }
				return .send(.presentationDestination(.dismiss))
			}

			Pullback(\.presentationDestination.tweetReply.event.didPostTweet.success) { state, _ in
				guard case .tweetReply = state.presentationDestination
				else { return .none }
				return .send(.presentationDestination(.dismiss))
			}
		}
	}

	@usableFromInline
	var alertReducer: some ReducerOf<Self> {
		Reduce { state, action in
			 switch action {
			 case .presentationDestination(.presented(.alert(.didTapAccept))):
				 return .send(.presentationDestination(.dismiss))

			 case let .presentationDestination(.presented(.alert(.didTapRecoveryOption(deeplink)))):
				 #warning("TODO: Handle deeplink")
				 return .send(.presentationDestination(.dismiss))

			 default:
				 return .none
			 }
		 }
	}

	func makeAlert(for error: APIClient.Error) -> AlertState<PresentationDestination.Action.AlertAction> {
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

extension TweetsFeedFeature {
	@Reducer
	public struct PresentationDestination {
		public init() {}

		@ObservableState
		public enum State: Equatable {
			case tweetReply(TweetReplyFeature.State)
			case alert(AlertState<Action.AlertAction>)
		}

		@CasePathable
		public enum Action: Equatable {
			case alert(AlertAction)
			case tweetReply(TweetReplyFeature.Action)

			@CasePathable
			public enum AlertAction: Equatable {
				case didTapAccept
				case didTapRecoveryOption(String)
			}
		}

		public var body: some ReducerOf<Self> {
			Scope(
				state: \.tweetReply,
				action: \.tweetReply,
				child: TweetReplyFeature.init
			)
		}
	}

	@Reducer
	public struct NavigationDestination {
		public init() {}

		@ObservableState
		public enum State: Equatable {
			case detail(TweetDetailFeature.State)
		}

		@CasePathable
		public enum Action: Equatable {
			case detail(TweetDetailFeature.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(
				state: \.detail,
				action: \.detail,
				child: TweetDetailFeature.init
			)
		}
	}
}

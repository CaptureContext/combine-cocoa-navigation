import _ComposableArchitecture
import LocalExtensions
import AppModels
import TweetFeature
import TweetsListFeature
import APIClient
import TweetReplyFeature

@Reducer
public struct TweetDetailFeature {
	public init() {}

	@Reducer
	public struct Destination {
		@ObservableState
		public enum State: Equatable {
			case detail(TweetDetailFeature.State)
			case tweetReply(TweetReplyFeature.State)
		}

		@CasePathable
		public enum Action: Equatable {
			case tweetReply(TweetReplyFeature.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(
				state: \.tweetReply,
				action: \.tweetReply,
				child: TweetReplyFeature.init
			)
		}
	}

	@ObservableState
	public struct State: Equatable {
		public var source: TweetFeature.State
		public var replies: TweetsListFeature.State

		@Presents
		public var detail: TweetDetailFeature.State?

		@Presents
		public var tweetReply: TweetReplyFeature.State?

		@Presents
		public var alert: AlertState<Action.Alert>?

		public init(
			source: TweetFeature.State,
			replies: TweetsListFeature.State = .init(),
			detail: TweetDetailFeature.State? = nil,
			tweetReply: TweetReplyFeature.State? = nil,
			alert: AlertState<Action.Alert>? = nil
		) {
			self.source = source
			self.replies = replies
			self.detail = detail
			self.tweetReply = tweetReply
			self.alert = alert
		}
	}

	@CasePathable
	public enum Action: Equatable {
		case source(TweetFeature.Action)
		case replies(TweetsListFeature.Action)
		case detail(PresentationAction<TweetDetailFeature.Action>)
		case tweetReply(PresentationAction<TweetReplyFeature.Action>)
		case fetchMoreReplies(reset: Bool = true)

		case alert(Alert)
		case delegate(Delegate)
		case event(Event)

		@CasePathable
		public enum Delegate: Equatable {
			case openProfile(USID)
		}

		@CasePathable
		public enum Alert: Equatable {
			case didTapAccept
			case didTapRecoveryOption(String)
		}

		@CasePathable
		public enum Event: Equatable {
			case didAppear
			case didFetchReplies(Result<FetchedTweets, APIClient.Error>)

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
	}

	@Dependency(\.apiClient)
	var apiClient

	public var body: some ReducerOf<Self> {
		CombineReducers {
			Reduce { state, action in
				switch action {
				case .source(.tapOnAuthor):
					return .send(.delegate(.openProfile(
						state.source.author.id
					)))

				case
					let .replies(.delegate(.openProfile(id))),
					let .detail(.presented(.delegate(.openProfile(id)))):
					return .send(.delegate(.openProfile(id)))

				default:
					return .none
				}
			}

			Pullback(\.replies.delegate.openDetail) { state, id in
				guard let tweet = state.replies.tweets[id: id]
				else { return .none }

				state.detail = .init(source: tweet)
				return .none
			}

			Pullback(\.event.didAppear) { state in
				return .send(.fetchMoreReplies())
			}

			Reduce { state, action in
				switch action {
				case let .fetchMoreReplies(reset):
					let id = state.source.id
					let repliesCount = reset ? 0 : state.replies.tweets.count
					return .run { send in
						await send(.event(.didFetchReplies(
							apiClient.tweet.fetchReplies(
								for: id,
								page: repliesCount / 10,
								limit: 10
							).map { tweets in
								Action.Event.FetchedTweets(
									tweets: tweets,
									reset: reset
								)
							}
						)))
					}

				case let .event(.didFetchReplies(replies)):
					switch replies {
					case let .success(replies):
						let tweets = replies.tweets.map { $0.convert(to: .tweetFeature) }
						if replies.reset {
							state.replies.tweets = .init(uniqueElements: tweets)
						} else {
							state.replies.tweets.append(contentsOf: tweets)
						}
						if state.replies.tweets.count > state.source.repliesCount {
							state.source.repliesCount = state.replies.tweets.count
						}
						state.replies.placeholder = .text()
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

			injectTweetReply(
				tweetState: \.source,
				tweetAction: \.source,
				state: \.$tweetReply,
				action: \.tweetReply,
				child: TweetReplyFeature.init
			)

			injectTweetReply(
				tweetsState: \.replies.tweets,
				tweetsAction: \.replies.tweets,
				state: \.$tweetReply,
				action: \.tweetReply,
				child: TweetReplyFeature.init
			)

			Scope(
				state: \State.source,
				action: \.source,
				child: TweetFeature.init
			)

			Scope(
				state: \State.replies,
				action: \.replies,
				child: TweetsListFeature.init
			)
		}
		.syncTweetDetailSource(
			state: \.$detail,
			with: \.source
		)
		.syncTweetDetailSource(
			state: \.$detail,
			with: \.replies
		)
		.ifLet(
			\State.$detail,
			action: \.detail,
			destination: TweetDetailFeature.init
		)
		.ifLet(
			\.$tweetReply,
			action: \.tweetReply,
			destination: TweetReplyFeature.init
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

extension Reducer {
	public func syncTweetDetailSource(
		state toTweetDetail: @escaping (State) -> PresentationState<TweetDetailFeature.State>,
		with toTweetsListState: WritableKeyPath<State, TweetsListFeature.State>
	) -> some ReducerOf<Self> {
		onChange(of: { toTweetDetail($0).wrappedValue?.source }) { state, old, new in
			guard let tweet = new else { return .none }
			state[keyPath: toTweetsListState].tweets[id: tweet.id] = tweet
			return .none
		}
	}

	public func syncTweetDetailSource(
		state toTweetDetail: @escaping (State) -> PresentationState<TweetDetailFeature.State>,
		with toTweetState: WritableKeyPath<State, TweetFeature.State>
	) -> some ReducerOf<Self> {
		onChange(of: { toTweetDetail($0).wrappedValue?.source }) { state, old, new in
			guard let tweet = new else { return .none }
			state[keyPath: toTweetState] = tweet
			return .none
		}
	}
}

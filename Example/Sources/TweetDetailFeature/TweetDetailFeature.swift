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

	@ObservableState
	public struct State: Equatable {
		public var source: TweetFeature.State
		public var replies: TweetsListFeature.State

		@Presents
		public var presentationDestination: PresentationDestination.State?

		@Presents
		public var navigationDestination: NavigationDestination.State?

		public init(
			source: TweetFeature.State,
			replies: TweetsListFeature.State = .init(),
			presentationDestination: PresentationDestination.State? = nil,
			navigationDestination: NavigationDestination.State? = nil
		) {
			self.source = source
			self.replies = replies
			self.presentationDestination = presentationDestination
			self.navigationDestination = navigationDestination
		}
	}

	@CasePathable
	public enum Action: Equatable {
		case source(TweetFeature.Action)
		case replies(TweetsListFeature.Action)
		case presentationDestination(PresentationAction<PresentationDestination.Action>)
		case navigationDestination(PresentationAction<NavigationDestination.Action>)
		case fetchMoreReplies(reset: Bool = true)
		case delegate(Delegate)
		case event(Event)

		@CasePathable
		public enum Delegate: Equatable {
			case openProfile(USID)
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
			openProfileReducer
			fetchTweetsReducer
			syncTweetReplyReducer
			alertReducer

			Pullback(\.replies.delegate.openDetail) { state, id in
				guard let tweet = state.replies.tweets[id: id]
				else { return .none }

				state.navigationDestination = .detail(.init(source: tweet))
				return .none
			}

			Pullback(\.event.didAppear) { state in
				return .send(.fetchMoreReplies())
			}

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
	}

	@usableFromInline
	var openProfileReducer: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case .source(.tapOnAuthor):
				return .send(.delegate(.openProfile(
					state.source.author.id
				)))

			case
				let .replies(.delegate(.openProfile(id))),
				let .navigationDestination(.presented(.detail(.delegate(.openProfile(id))))):
				return .send(.delegate(.openProfile(id)))

			default:
				return .none
			}
		}
	}

	@usableFromInline
	var syncTweetReplyReducer: some ReducerOf<Self> {
		CombineReducers {
			Pullback(\.source.reply) { state, id in
				state.presentationDestination = .tweetReply(.init(source: state.source))
				return .none
			}

			Pullback(\.replies.tweets, action: \.reply) { state, id in
				state.replies.tweets[id: id].map { tweet in
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
	var fetchTweetsReducer: some ReducerOf<Self> {
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
					state.presentationDestination = .alert(makeAlert(for: error))
					return .none
				}

			default:
				return .none
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

	func makeAlert(for error: APIClient.Error) -> AlertState<PresentationDestination.Action.Alert> {
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
	public func syncTweetList(
		state toTweetsListState: WritableKeyPath<State, TweetsListFeature.State>,
		with toTweetDetail: @escaping (State) -> PresentationState<TweetDetailFeature.State>
	) -> some ReducerOf<Self> {
		onChange(of: { toTweetDetail($0).wrappedValue?.source }) { state, old, new in
			guard let tweet = new else { return .none }
			state[keyPath: toTweetsListState].tweets[id: tweet.id] = tweet
			return .none
		}
	}

	public func syncTweet(
		state toTweetState: WritableKeyPath<State, TweetFeature.State>,
		with toTweetDetail: @escaping (State) -> PresentationState<TweetDetailFeature.State>
	) -> some ReducerOf<Self> {
		onChange(of: { toTweetDetail($0).wrappedValue?.source }) { state, old, new in
			guard
				let tweet = new,
				state[keyPath: toTweetState].id == tweet.id
			else { return .none }
			state[keyPath: toTweetState] = tweet
			return .none
		}
	}
}

extension TweetDetailFeature {
	@Reducer
	public struct PresentationDestination {
		@ObservableState
		public enum State: Equatable {
			case tweetReply(TweetReplyFeature.State)
			case alert(AlertState<Action.Alert>)
		}

		@CasePathable
		public enum Action: Equatable {
			case tweetReply(TweetReplyFeature.Action)
			case alert(Alert)

			@CasePathable
			public enum Alert: Equatable {
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

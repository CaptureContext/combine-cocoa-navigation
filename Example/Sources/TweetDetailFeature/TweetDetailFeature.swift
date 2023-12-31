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
			case detail(TweetDetailFeature.Action)
			case tweetReply(TweetReplyFeature.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(
				state: \.detail,
				action: \.detail,
				child: TweetDetailFeature.init
			)
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
		public var destination: Destination.State?

		@Presents
		public var alert: AlertState<Action.Alert>?

		public init(
			source: TweetFeature.State,
			replies: TweetsListFeature.State = .init(),
			destination: Destination.State? = nil,
			alert: AlertState<Action.Alert>? = nil
		) {
			self.source = source
			self.replies = replies
			self.destination = destination
			self.alert = alert
		}
	}

	@CasePathable
	public enum Action: Equatable {
		case source(TweetFeature.Action)
		case replies(TweetsListFeature.Action)
		case destination(PresentationAction<Destination.Action>)
		case fetchMoreReplies

		case alert(Alert)
		case delegate(Delegate)
		case event(Event)

		@CasePathable
		public enum Delegate: Equatable {
			case openProfile(USID)
		}

		@CasePathable
		public enum Alert: Equatable {
			case close
			case didTapRecoveryOption(String)
		}

		@CasePathable
		public enum Event: Equatable {
			case didAppear
			case didFetchReplies(Result<[TweetModel], APIClient.Error>)
		}
	}

	@Dependency(\.apiClient)
	var apiClient

	public var body: some ReducerOf<Self> {
		CombineReducers {
			Reduce { state, action in
				switch action {
				case .source(.tapOnAuthor):
					return .send(.delegate(.openProfile(state.source.id)))

				case
					let .replies(.delegate(.openProfile(id))),
					let .destination(.presented(.detail(.delegate(.openProfile(id))))):
					return .send(.delegate(.openProfile(id)))

				default:
					return .none
				}
			}

			Reduce { state, action in
				switch action {
				case .source(.reply):
					state.destination = .tweetReply(.init(source: state.source, replyText: ""))
					return .none

				case let .replies(.tweets(.element(id, .reply))):
					guard let tweet = state.replies.tweets[id: id] else { return .none }
					state.destination = .tweetReply(.init(source: tweet, replyText: ""))
					return .none

				default:
					return .none
				}
			}

			Pullback(\.replies.delegate.openDetail) { state, id in
				guard let tweet = state.replies.tweets[id: id]
				else { return .none }

				state.destination = .detail(.init(source: tweet))
				return .none
			}

			Pullback(\.event.didAppear) { state in
				return .send(.fetchMoreReplies)
			}

			Reduce { state, action in
				switch action {
				case .fetchMoreReplies:
					let id = state.source.id
					let repliesCount = state.replies.tweets.count
					return .run { send in
						await send(.event(.didFetchReplies(
							apiClient.tweet.fetchReplies(
								for: id,
								page: repliesCount / 10,
								limit: 10
							)
						)))
					}

				case let .event(.didFetchReplies(replies)):
					switch replies {
					case let .success(replies):
						let tweets = replies.map { $0.convert(to: .tweetFeature) }
						state.replies.tweets.append(contentsOf: tweets)
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
			\State.$destination,
			action: \.destination,
			 destination: Destination.init
		)
		.syncTweetDetailSource(\.$destination.detail, with: \.replies)
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

extension Reducer {
	public func syncTweetDetailSource(
		_ toTweetDetail: @escaping (State) -> PresentationState<TweetDetailFeature.State>,
		with toTweetsListState: WritableKeyPath<State, TweetsListFeature.State>
	) -> some ReducerOf<Self> {
		onChange(of: { toTweetDetail($0).wrappedValue?.source }) { state, old, new in
			guard let tweet = new else { return .none }
			state[keyPath: toTweetsListState].tweets[id: tweet.id] = tweet
			return .none
		}
	}
}

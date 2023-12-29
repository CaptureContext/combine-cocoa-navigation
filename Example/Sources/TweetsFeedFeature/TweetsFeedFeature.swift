import _ComposableArchitecture
import LocalExtensions
import APIClient
import TweetsListFeature
import TweetDetailFeature

@Reducer
public struct TweetsFeedFeature {
	public init() {}

	@ObservableState
	public struct State: Equatable {
		public var list: TweetsListFeature.State

		@Presents
		public var detail: TweetDetailFeature.State?

		public init(
			list:  TweetsListFeature.State = .init(),
			detail: TweetDetailFeature.State? = nil
		) {
			self.list = list
			self.detail = detail
		}
	}

	public enum Action: Equatable {
		case list(TweetsListFeature.Action)
		case detail(PresentationAction<TweetDetailFeature.Action>)
		case openProfile(USID)
		case openDetail(TweetDetailFeature.State)
	}

	@Dependency(\.apiClient)
	var apiClient

	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case
				let .list(.tweets(.element(_, .openProfile(id)))),
				let .detail(.presented(.openProfile(id))):
				return .send(.openProfile(id))

			case let .list(.tweets(.element(itemID, .openDetail))):
				return .run { send in
					do {
						let tweet = try await apiClient.tweet.fetch(id: itemID).get()
						let replies = try await apiClient.tweet.fetchReplies(for: itemID).get()

						await send(.openDetail(.init(
							source: tweet.convert(to: .tweetFeature),
							replies: .init(tweets: .init(
								uniqueElements: replies.map { $0.convert(to: .tweetFeature) }
							))
						)))
					} catch {
						#warning("Error is not handled")
						fatalError("ErrorIsNotHandled: \(error.localizedDescription)")
					}
				}

			case let .openDetail(detail):
				state.detail = detail
				return .none

			default:
				return .none
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
}

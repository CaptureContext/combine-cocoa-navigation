import _ComposableArchitecture
import Foundation

@Reducer
public struct TweetsListFeature {
	public init() {}

	@ObservableState
	public struct State: Equatable {
		public init(tweets: IdentifiedArrayOf<TweetFeature.State> = []) {
			self.tweets = tweets
		}

		public var tweets: IdentifiedArrayOf<TweetFeature.State>
	}

	public enum Action: Equatable {
		case tweets(IdentifiedActionOf<TweetFeature>)
		case openDetail(for: UUID)
		case openProfile(UUID)
	}

	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case let .tweets(.element(_, .openProfile(id))):
				return .send(.openProfile(id))

			case let .tweets(.element(_, .openDetail(id))):
				return .send(.openDetail(for: id))

			default:
				return .none
			}
		}
		.forEach(
			\State.tweets,
			 action: \.tweets,
			 element: TweetFeature.init
		)
	}
}

import _ComposableArchitecture
import LocalExtensions
import AppModels
import TweetFeature

@Reducer
public struct ProfileFeedFeature {
	public init() {}

	@ObservableState
	public struct State: Equatable {
		public var tweets: IdentifiedArrayOf<TweetFeature.State>

		public init(
			tweets: IdentifiedArrayOf<TweetFeature.State> = []
		) {
			self.tweets = tweets
		}
	}

	public enum Action: Equatable {
		case tweets(IdentifiedActionOf<TweetFeature>)
		case openProfile(UUID)
	}

	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case let .tweets(.element(id, action: .tapOnAuthor)):
				return .send(.openProfile(id))

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

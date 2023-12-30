import _ComposableArchitecture
import LocalExtensions
import TweetFeature

@Reducer
public struct TweetsListFeature {
	public init() {}

	@ObservableState
	public struct State: Equatable {
		@ObservableState
		public enum Placeholder: Equatable {
			case text(String = "Nothing here yet 😢")
			case activityIndicator
		}

		public init(
			tweets: IdentifiedArrayOf<TweetFeature.State> = [],
			placeholder: Placeholder? = .activityIndicator
		) {
			self.tweets = tweets
			self.placeholder = placeholder
		}

		public var tweets: IdentifiedArrayOf<TweetFeature.State>
		public var placeholder: Placeholder?
	}

	@CasePathable
	public enum Action: Equatable {
		case tweets(IdentifiedActionOf<TweetFeature>)
		case delegate(Delegate)

		@CasePathable
		public enum Delegate: Equatable {
			case openDetail(USID)
			case openProfile(USID)
		}
	}

	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case let .tweets(.element(id, .tap)):
				return .send(.delegate(.openDetail(id)))

			case let .tweets(.element(id, .tapOnAuthor)):
				return .send(.delegate(.openProfile(id)))

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

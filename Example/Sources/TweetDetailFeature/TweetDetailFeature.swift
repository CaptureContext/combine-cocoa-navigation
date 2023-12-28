import _ComposableArchitecture
import LocalExtensions
import AppModels
import TweetFeature
import TweetsListFeature
import APIClient

@Reducer
public struct TweetDetailFeature {
	public init() {}

	@ObservableState
	public struct State: Equatable {
		public var source: TweetFeature.State
		public var replies: TweetsListFeature.State

		@Presents
		public var detail: TweetDetailFeature.State?

		public init(
			source: TweetFeature.State,
			replies: TweetsListFeature.State,
			detail: TweetDetailFeature.State? = nil
		) {
			self.source = source
			self.replies = replies
			self.detail = detail
		}
	}

	public enum Action: Equatable {
		case source(TweetFeature.Action)
		case replies(TweetsListFeature.Action)
		case detail(PresentationAction<Action>)
		case openProfile(USID)
	}

	@Dependency(\.apiClient)
	var apiClient

	public var body: some ReducerOf<Self> {
		CombineReducers {
			Reduce { state, action in
				switch action {
				case
					let .source(.openProfile(id)),
					let .replies(.openProfile(id)),
					let .detail(.presented(.openProfile(id))):
					return .send(.openProfile(id))

				case let .replies(.openDetail(id)):
					#warning("Not handled")
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
			\State.$detail,
			action: \.detail,
			destination: { TweetDetailFeature() }
		)
	}
}

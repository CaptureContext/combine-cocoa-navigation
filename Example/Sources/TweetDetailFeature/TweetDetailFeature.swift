import _ComposableArchitecture
import Foundation
import AppModels
import TweetFeature
import TweetsListFeature

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

		public static func collectMock(
		 for id: UUID
	 ) -> Self? {
		 TweetModel.mockTweets[id: id].map { source in
			 return .init(
				 source: .mock(model: source),
				 replies: .init(
					tweets: IdentifiedArray(
						uncheckedUniqueElements: TweetModel
							.mockReplies(for: source.id)
							.map { .mock(model: $0) }
					)
				 )
			 )
		 }
	 }
	}

	public enum Action: Equatable {
		case source(TweetFeature.Action)
		case replies(TweetsListFeature.Action)
		case detail(PresentationAction<Action>)
		case openProfile(UUID)
	}

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
					state.detail = .collectMock(for: id)

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

import ComposableArchitecture
import Foundation

public struct TweetFeature: Reducer {
	public init() {}

	public struct State: Equatable, Identifiable {
		public var id: UUID
		public var replyTo: UUID?
		public var author: UserModel
		public var text: String

		public init(
			id: UUID,
			replyTo: UUID? = nil,
			author: UserModel,
			text: String
		) {
			self.id = id
			self.replyTo = replyTo
			self.author = author
			self.text = text
		}
	}

	@CasePathable
	public enum Action: Equatable {
		case tap
		case tapOnAuthor
		case openDetail(for: UUID)
		case openProfile(UUID)
	}

	public func reduce(
		into state: inout State,
		action: Action
	) -> Effect<Action> {
		switch action {
		case .tap:
			return .send(.openDetail(for: state.id))

		case .tapOnAuthor:
			return.send(.openProfile(state.author.id))

		default:
			return .none
		}
	}
}

extension TweetFeature.State {
	public static func mock(
		model: TweetModel
	) -> Self {
		.mock(
			id: model.id,
			replyTo: model.replyTo,
			author: .mock(id: model.authorID),
			text: model.text
		)
	}

	public static func mock(
		id: UUID = .init(),
		replyTo: UUID? = nil,
		author: UserModel = .mock(),
		text: String = """
		Nisi commodo non ea consequat qui ad pariatur dolore elit ipsum laboris ipsum. \
		Culpa anim incididunt sunt minim ut eiusmod nulla mollit minim qui. \
		In ad laboris labore irure ea ea officia.
		"""
	 ) -> Self {
		.init(
			id: id,
			replyTo: replyTo,
			author: author,
			text: text
		)
	}

	public func mockReply(
		id: UUID = .init(),
		author: UserModel = .mock(),
		text: String = """
		Nisi commodo non ea consequat qui ad pariatur dolore elit ipsum laboris ipsum. \
		Culpa anim incididunt sunt minim ut eiusmod nulla mollit minim qui. \
		In ad laboris labore irure ea ea officia.
		"""
	 ) -> Self {
		.init(
			id: id,
			replyTo: self.id,
			author: author,
			text: text
		)
	}
}

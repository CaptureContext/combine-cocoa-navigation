import LocalExtensions

public struct TweetModel: Equatable, Identifiable, Codable {
	public var id: UUID
	public var authorID: UUID
	public var replyTo: UUID?
	public var text: String

	public init(
		id: UUID,
		authorID: UUID,
		replyTo: UUID? = nil,
		text: String
	) {
		self.id = id
		self.authorID = authorID
		self.replyTo = replyTo
		self.text = text
	}
}

extension TweetModel {
	public static func mock(
		id: UUID = .init(),
		authorID: UUID = UserModel.mock().id,
		replyTo: UUID? = nil,
		text: String =  """
		Nisi commodo non ea consequat qui ad pariatur dolore elit ipsum laboris ipsum. \
		Culpa anim incididunt sunt minim ut eiusmod nulla mollit minim qui. \
		In ad laboris labore irure ea ea officia.
		"""
	) -> TweetModel {
		.init(
			id: id,
			authorID: authorID,
			replyTo: replyTo,
			text: text
		)
	}

	public func withReplies(
		@TweetModelsBuilder replies: (TweetModel) -> [TweetModel]
	) -> [TweetModel] {
		[self] + replies(self)
	}
}

@resultBuilder
public struct TweetModelsBuilder: ArrayBuilderProtocol {
	public typealias Element = TweetModel
}

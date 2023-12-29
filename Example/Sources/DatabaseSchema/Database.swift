import _Dependencies

public actor Database: Sendable {
	public let context: ModelContext

	public init(context: ModelContext) {
		self.context = context
	}
}

// Not sure if it's okay, just wanted to silence warnings
// this file is just mock implementation that uses local database
// for backend work simulation 😁
extension ModelContext: @unchecked Sendable {}

extension Database: DependencyKey {
	public static var liveValue: Database {
		try! .init(context: DatabaseSchema.createModelContext(.file()))
	}

	public static var previewValue: Database {
		try! .init(context: DatabaseSchema.createModelContext(.inMemory))
	}
}

extension DependencyValues {
	public var database: Database {
		get { self[Database.self] }
		set { self[Database.self] = newValue }
	}
}

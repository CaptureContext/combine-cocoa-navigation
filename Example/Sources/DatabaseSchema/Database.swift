import _Dependencies

public actor Database: Sendable {
	private let container: ModelContainer

	public init(container: ModelContainer) {
		self.container = container
	}

	@discardableResult
	public func withContainer<T>(_ operation: (ModelContainer) async throws -> T) async rethrows -> T {
		return try await operation(container)
	}

	@discardableResult
	public func withContext<T>(_ operation: (ModelContext) async throws -> T) async rethrows -> T {
		return try await withContainer { container in
			try await operation(ModelContext(container))
		}
	}
}

// Not sure if it's okay, just wanted to silence warnings
// this file is just mock implementation that uses local database
// for backend work simulation 😁
extension ModelContext: @unchecked Sendable {}

extension Database: DependencyKey {
	public static var liveValue: Database {
		try! .init(container: DatabaseSchema.createModelContainer(.file()))
	}

	public static var previewValue: Database {
		try! .init(container: DatabaseSchema.createModelContainer(.inMemory))
	}
}

extension DependencyValues {
	public var database: Database {
		get { self[Database.self] }
		set { self[Database.self] = newValue }
	}
}

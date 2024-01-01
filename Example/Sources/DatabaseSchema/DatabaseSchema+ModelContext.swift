import SwiftData
import LocalExtensions

extension DatabaseSchema {
	public enum ModelPersistance {
		case inMemory
		case file(URL = .applicationSupportDirectory.appending(path: "db.store"))
	}

	public static func createModelContainer(
		_ persistance: ModelPersistance
	) throws -> ModelContainer {
		
		let config = switch persistance {
		case .inMemory:
			ModelConfiguration(isStoredInMemoryOnly: true)
		case let .file(url):
			ModelConfiguration(url: url)
		}

		let container = try ModelContainer(
			for: TweetModel.self, UserModel.self,
			migrationPlan: DatabaseSchema.MigrationPlan.self,
			configurations: config
		)

		return container
	}
}

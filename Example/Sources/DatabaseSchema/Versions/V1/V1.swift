import SwiftData
import LocalExtensions

extension DatabaseSchema {
	public enum V1: VersionedSchema {
		public static let versionIdentifier: Schema.Version = .init(1, 0, 0)
		public static var models: [any PersistentModel.Type] {
			[
				TweetModel.self,
				UserModel.self
			]
		}
	}
}

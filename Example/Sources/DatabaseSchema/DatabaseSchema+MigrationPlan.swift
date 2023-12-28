import SwiftData

extension DatabaseSchema {
	public enum MigrationPlan: SchemaMigrationPlan {
		public static var stages: [MigrationStage] {
			[]
		}

		public static var schemas: [any VersionedSchema.Type] {
			[V1.self]
		}
	}
}

@_exported import SwiftData
import Foundation

extension DatabaseSchema {
	public typealias TweetModel = Current.TweetModel
	public typealias UserModel = Current.UserModel
}

extension PersistentModel {
	public typealias Fetch = FetchDescriptor<Self>
	public typealias Sort = SortDescriptor<Self>
	public typealias Predicate = Foundation.Predicate<Self>
}

extension ModelContext {
	public func fetch<Model: PersistentModel>(
		_ model: Model.Type = Model.self,
		_ predicate: Model.Predicate,
		sortBy sortDescriptors: [Model.Sort] = []
	) throws -> [Model] {
		return try fetch(Model.Fetch(
			predicate: predicate,
			sortBy: sortDescriptors
		))
	}
}

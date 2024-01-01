@_exported import SwiftData
import Foundation
import _Dependencies

extension DatabaseSchema {
	public typealias TweetModel = Current.TweetModel
	public typealias UserModel = Current.UserModel
}

extension PersistentModel {
	public typealias Fetch = FetchDescriptor<Self>
	public typealias Sort = SortDescriptor<Self>
	public typealias Predicate = Foundation.Predicate<Self>
	
	@discardableResult
	public func insert(to context: ModelContext) -> Self {
		context.insert(self)
		return self
	}
	
	@discardableResult
	public func update<Value>(
		_ keyPath: ReferenceWritableKeyPath<Self, Value>,
		with closure: (inout Value) -> Void
	) -> Self {
		closure(&self[keyPath: keyPath])
		return self
	}
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

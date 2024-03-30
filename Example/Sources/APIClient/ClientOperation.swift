import DeclarativeConfiguration
import Foundation

public protocol ClientOperation {
	associatedtype Input
	associatedtype Output

	typealias AsyncSignature = @Sendable (Input) async -> Output

	var asyncCall: AsyncSignature { get }

	init(_ asyncCall: @escaping AsyncSignature)
}

extension ClientOperation {
	public func intercepted(
		with handler: (Self) -> AsyncSignature
	) -> Self {
		.init(handler(self))
	}
}

public protocol ClientOperationsGroup {}

extension ClientOperationsGroup {
	func with<Operation: ClientOperation>(
		_ operation: WritableKeyPath<Self, Operation>,
		interceptedBy handler: @escaping (Operation) -> Operation.AsyncSignature
	) -> Self {
		reduce(self) { _self in
			_self[keyPath: operation] = _self[keyPath: operation].intercepted(with: handler)
		}
	}
}

extension ClientOperationsGroup {
	func with<Operation: ClientOperation>(
		_ operation: WritableKeyPath<Self, Operation>,
		delayedBy seconds: @escaping @autoclosure () -> TimeInterval
	) -> Self {
		with(operation, interceptedBy: { impl in
			return { input in
				try? await Task.sleep(nanoseconds: UInt64(seconds() * pow(10, 9)))
				return await impl.asyncCall(input)
			}
		})
	}
}

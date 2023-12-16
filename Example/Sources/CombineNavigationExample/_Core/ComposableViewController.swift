import ComposableArchitecture
import UIKit
import Combine
import Capture

public typealias ComposableViewControllerOf<R: Reducer> = ComposableViewController<
	R.State,
	R.Action
> where R.State: Equatable, R.Action: Equatable

open class ComposableViewController<
	State: Equatable,
	Action: Equatable
>: UIViewController {
	public typealias Store = ComposableArchitecture.Store<State, Action>
	public typealias StorePublisher = ComposableArchitecture.StorePublisher<State>

	private var stateCancellables: Set<AnyCancellable> = []
	private var storeCancellable: Cancellable?
	private var store: Store?
	private var viewStore: ViewStore<State, Action>?

	private func releaseStore() {
		stateCancellables = []
		storeCancellable = nil
		store = nil
		viewStore = nil
		scope(nil)
	}

	public func setStore(_ store: ComposableArchitecture.Store<State?, Action>?) {
		guard let store else { return releaseStore() }
		storeCancellable = store.ifLet(
			then: capture { _self, store in
				_self.setStore(store)
			},
			else: capture { _self in
				_self.releaseStore()
			}
		)
	}

	public func setStore(_ store: Store?) {
		guard let store else { return releaseStore() }
		self.store = store

		let viewStore = ViewStore(store, observe: { $0 })
		self.viewStore = viewStore

		self.scope(store)
		self.bind(viewStore.publisher, into: &stateCancellables)
	}

	open func scope(_ store: Store?) {}

	open func bind(
		_ publisher: StorePublisher,
		into cancellables: inout Set<AnyCancellable>
	) {}

	public func withViewStore(_ action: (ViewStore<State, Action>) -> Void) {
		viewStore.map(action)
	}

	public func send(_ action: Action) {
		viewStore?.send(action)
	}

	public func sendPop<S, A>(
		_ ids: [StackElementID],
		from actionPath: CaseKeyPath<Action, StackAction<S, A>>
	) {
		ids.first.map { id in
			send(actionPath.callAsFunction(.popFrom(id: id)))
		}
	}

	public func captureSend(_ action: Action) -> () -> Void {
		return capture { _self in _self.send(action) }
	}
}

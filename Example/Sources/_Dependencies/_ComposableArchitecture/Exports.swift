@_exported import ComposableExtensions

extension ComposableViewController {
	public func sendPop<S, A>(
		_ ids: [StackElementID],
		from actionPath: CaseKeyPath<Action, StackAction<S, A>>
	) {
		ids.first.map { id in
			_ = store?.send(actionPath.callAsFunction(.popFrom(id: id)))
		}
	}
}

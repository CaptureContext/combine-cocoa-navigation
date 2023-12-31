import _ComposableArchitecture
import SwiftUI
import AppModels
import TweetFeature

public struct ProfileFeedView: ComposableView {
	let store: StoreOf<ProfileFeedFeature>

	public init(_ store: StoreOf<ProfileFeedFeature>) {
		self.store = store
	}

	public var body: some View {
		ScrollView(.vertical) {
			LazyVStack(spacing: 24) {
				ForEachStore(
					store.scope(
						state: \.tweets,
						action: \.tweets
					),
					content: TweetView.init
				)
			}
		}
	}
}

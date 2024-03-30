import _ComposableArchitecture
import SwiftUI
import CocoaExtensions
import CombineExtensions
import CombineNavigation
import TweetsListFeature
import TweetDetailFeature
import TweetReplyFeature

@RoutingController
public final class TweetsFeedController: ComposableHostingController<TweetsFeedView> {
	@ComposablePresentationDestination(container: .navigation.container { $0
		.modalPresentationStyle(.fullScreen)
	})
	var tweetReplyController: ComposableHostingController<TweetReplyView>?

	@ComposableTreeDestination
	var detailController: TweetDetailController?

	public override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.store?.send(.event(.didAppear))
	}

	public override func scope(_ store: Store?) {
		super.scope(store)

		_tweetReplyController.setStore(store?.scope(
			state: \.presentationDestination?.tweetReply,
			action: \.presentationDestination.tweetReply
		))

		_detailController.setStore(store?.scope(
			state: \.navigationDestination?.detail,
			action: \.navigationDestination.detail
		))
	}

	public override func bind(
		_ publisher: StorePublisher,
		into cancellables: inout Set<AnyCancellable>
	) {
		presentationDestination(
			isPresented: \.$presentationDestination[case: \.tweetReply].isNotNil,
			destination: $tweetReplyController,
			dismissAction: .presentationDestination(.dismiss)
		)
		.store(in: &cancellables)

		navigationDestination(
			isPresented: \.navigationDestination[case: \.detail].isNotNil,
			destination: $detailController,
			popAction: .navigationDestination(.dismiss)
		)
		.store(in: &cancellables)
	}
}


public struct TweetsFeedView: ComposableView {
	private let store: StoreOf<TweetsFeedFeature>

	public init(_ store: StoreOf<TweetsFeedFeature>) {
		self.store = store
	}

	public var body: some View {
		TweetsListView(store.scope(
			state: \.list, 
			action: \.list
		))
	}
}

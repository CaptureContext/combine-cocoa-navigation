import _ComposableArchitecture
import CocoaExtensions
import CombineExtensions
import CombineNavigation
import TweetsListFeature
import TweetDetailFeature

@RoutingController
public final class TweetsFeedController: ComposableViewControllerOf<TweetsFeedFeature> {
	let host = ComposableHostingController<TweetsListView>()

	@ComposableTreeDestination
	var detailController: TweetDetailController?

	public override func viewDidLoad() {
		super.viewDidLoad()
		self.addChild(host)
		self.view.addSubview(host.view)
		host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		host.view.frame = view.bounds
		host.didMove(toParent: self)
	}

	public override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.store?.send(.event(.didAppear))
	}

	public override func scope(_ store: Store?) {
		host.setStore(store?.scope(
			state: \.list,
			action: \.list
		))

		_detailController.setStore(store?.scope(
			state: \.detail,
			action: \.detail.presented
		))
	}

	public override func bind(
		_ publisher: StorePublisher,
		into cancellables: inout Set<AnyCancellable>
	) {
		navigationDestination(
			isPresented: \.$detail.wrappedValue.isNotNil,
			destination: $detailController,
			popAction: .detail(.dismiss)
		)
		.store(in: &cancellables)
	}
}

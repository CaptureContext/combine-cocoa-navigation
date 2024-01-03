import _ComposableArchitecture
import CocoaExtensions
import CombineExtensions
import CombineNavigation
import UserProfileFeature
import TweetsFeedFeature
import AppUI
import CocoaAliases
import TweetPostFeature
import TweetReplyFeature

@RoutingController
public final class FeedTabController: ComposableViewControllerOf<FeedTabFeature> {
	let contentController: TweetsFeedController = .init()

	var presentationCancellables: [AnyHashable: Cancellable] = [:]
	var contentView: ContentView! { view as? ContentView }

	public override func loadView() {
		self.view = ContentView()
	}

	@ComposableViewPresentationDestination<TweetPostView>
	var postTweetController

	@ComposableStackDestination<TweetsFeedController>
	var feedControllers

	@ComposableViewStackDestination<UserProfileView>
	var profileControllers

	public override func viewDidLoad() {
		super.viewDidLoad()

		// For direct children this method is used instead of addChild
		self.addRoutedChild(contentController)
		self.contentView?.contentView.addSubview(contentController.view)
		contentController.view.pinToSuperview()
		contentController.didMove(toParent: self)
	}

	public override func scope(_ store: Store?) {
		contentController.setStore(store?.scope(
			state: \.feed,
			action: \.feed
		))

		_postTweetController.setStore(store?.scope(
			state: \.postTweet,
			action: \.postTweet.presented
		))

		_feedControllers.setStore { id in
			store?.scope(
				state: \.path[id: id]?.feed,
				action: \.path[id: id].feed
			)
		}

		_profileControllers.setStore { id in
			store?.scope(
				state: \.path[id: id]?.profile,
				action: \.path[id: id].profile
			)
		}
	}

	public override func bind(
		_ publisher: StorePublisher,
		into cancellables: inout Set<AnyCancellable>
	) {
		contentView?.tweetButton.onAction(perform: capture { _self in
			_self.store?.send(.tweet)
		})

		#warning("Should introduce an API to wrap controller in Navigation")
		presentationDestination(
			isPresented: \.$postTweet.wrappedValue.isNotNil,
			destination: $postTweetController,
			dismissAction: .postTweet(.dismiss)
		)
		.store(in: &cancellables)

		navigationStack(
			state: \.path,
			action: \.path,
			switch: { destinations, route in
				switch route {
				case .feed:
					destinations.$feedControllers
				case .profile:
					destinations.$profileControllers
				}
			}
		)
		.store(in: &cancellables)
	}
}

extension FeedTabController {
	final class ContentView: CustomCocoaView {
		let contentView: CocoaView = .init { $0
			.translatesAutoresizingMaskIntoConstraints(false)
		}

		let tweetButton = CustomButton<UIImageView> { $0
			.translatesAutoresizingMaskIntoConstraints(false)
			.content.scope { $0
				.image(.init(systemName: "plus"))
				.contentMode(.center)
				.backgroundColor(.systemBlue)
				.tintColor(.white)
			}
		}.modifier(.rounded(radius: 24))

		override func _init() {
			super._init()

			addSubview(contentView)
			contentView.pinToSuperview()

			addSubview(tweetButton)
			NSLayoutConstraint.activate([
				tweetButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -24),
				tweetButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -24),
				tweetButton.widthAnchor.constraint(equalToConstant: 48),
				tweetButton.heightAnchor.constraint(equalToConstant: 48)
			])
		}
	}
}

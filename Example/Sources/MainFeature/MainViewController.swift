import _ComposableArchitecture
import FoundationExtensions
import CombineNavigation
import AppUI
import CocoaAliases
import FeedTabFeature
import ProfileTabFeature

public final class MainViewController: ComposableTabBarControllerOf<MainFeature>, UITabBarControllerDelegate {
	let feedTabController: FeedTabController = .init()
	let profileTabController: ProfileTabController = .init()

	public override func _init() {
		super._init()

		let feedNavigation = UINavigationController(
			rootViewController: feedTabController.configured { $0
				.title("Example")
				.set { $0.tabBarItem = .init(
					title: "Feed",
					image: UIImage(systemName: "house"),
					selectedImage: UIImage(systemName: "house.fill")
				) }
			}
		)

		let profileNavigation = UINavigationController(
			rootViewController: profileTabController.configured { $0
				.set { $0.tabBarItem = .init(
					title: "Profile",
					image: UIImage(systemName: "person"),
					selectedImage: UIImage(systemName: "person.fill")
				) }
			}
		)

		feedNavigation.navigationBar.prefersLargeTitles = true

		setViewControllers(
			[
				feedNavigation,
				profileNavigation
			],
			animated: false
		)
	}

	public override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.store?.send(.event(.didAppear))
	}

	public override func scope(_ store: Store?) {
		feedTabController.setStore(store?.scope(
			state: \.feed,
			action: \.feed
		))

		profileTabController.setStore(store?.scope(
			state: \.profile,
			action: \.profile
		))
	}

	public override func bind(
		_ state: StorePublisher,
		into cancellables: inout Cancellables
	) {
		publisher(for: \.selectedIndex)
			.sinkValues(capture { _self, index in
				guard
					let controller = _self.controller(for: index),
					let tab = _self.tab(for: controller)
				else { return }

				_self.store?.send(.binding(.set(\.selectedTab, tab)))
			})
			.store(in: &cancellables)

		state.selectedTab
			.sinkValues(capture { _self, tab in
				_self.index(of: _self.controller(for: tab)).map { index in
					_self.selectedIndex = index
				}
			})
			.store(in: &cancellables)
	}

	func index(of controller: CocoaViewController) -> Int? {
		viewControllers?.firstIndex(of: controller)
	}

	func controller(for tab: State.Tab) -> CocoaViewController {
		switch tab {
		case .feed:
			return feedTabController
		case .profile:
			return profileTabController
		}
	}

	func controller(for index: Int) -> CocoaViewController? {
		return viewControllers?[safe: index]
	}

	func tab(for controller: CocoaViewController) -> State.Tab? {
		switch controller {
		case feedTabController:
			return .feed
		case profileTabController:
			return .profile
		default:
			return nil
		}
	}
}

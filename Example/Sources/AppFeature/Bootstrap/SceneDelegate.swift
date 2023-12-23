//
//  SceneDelegate.swift
//  Example
//
//  Created by Maxim Krouk on 11.11.2023.
//

import _ComposableArchitecture
import AppUI
import AppModels
import FeedTabFeature

public class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	public var window: UIWindow?
	let store = Store(
		initialState: FeedTabFeature.State(
			feed: .init(
				list: .init(
					tweets: .init(
						uncheckedUniqueElements: TweetModel
							.mockTweets.filter(\.replyTo.isNil)
							.map { .mock(model: $0) }
					)
				)
			)
		),
		reducer: {
			FeedTabFeature()._printChanges()
		}
	)

	public func scene(
		_ scene: UIScene,
		willConnectTo session: UISceneSession,
		options connectionOptions: UIScene.ConnectionOptions
	) {
		guard let scene = scene as? UIWindowScene else { return }
		let controller = FeedTabController()
		controller.setStore(store)

		let window = UIWindow(windowScene: scene)
		self.window = window

		window.rootViewController = UINavigationController(
			rootViewController: controller
		)

		window.makeKeyAndVisible()
	}

	public func sceneDidDisconnect(_ scene: UIScene) {}
	public func sceneDidBecomeActive(_ scene: UIScene) {}
	public func sceneWillResignActive(_ scene: UIScene) {}
	public func sceneWillEnterForeground(_ scene: UIScene) {}
	public func sceneDidEnterBackground(_ scene: UIScene) {}
}


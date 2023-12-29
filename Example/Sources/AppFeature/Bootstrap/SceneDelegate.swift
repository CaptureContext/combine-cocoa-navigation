//
//  SceneDelegate.swift
//  Example
//
//  Created by Maxim Krouk on 11.11.2023.
//

import _ComposableArchitecture
import AppUI
import AppModels
import MainFeature
import DatabaseSchema
import LocalExtensions

public class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	public var window: UIWindow?

	@Dependency(\.database)
	var database

	@Dependency(\.apiClient)
	var apiClient

	func setupStore(_ callback: @escaping (StoreOf<MainFeature>) -> Void) {
		Task<Void, Never> { @MainActor in
			do {
				let modelContext = await database.context

				let currentUser = DatabaseSchema.UserModel(
					id: USID(),
					username: "capturecontext",
					password: .sha256("psswrd")!
				)

				let tweet = DatabaseSchema.TweetModel(
					id: USID(),
					author: currentUser,
					content: "Hello, First World!"
				)

				let reply1 = DatabaseSchema.TweetModel(
					id: USID(),
					author: currentUser,
					replySource: tweet,
					content: "Hello, Second World!"
				)

				let reply2 = DatabaseSchema.TweetModel(
					id: USID(),
					author: currentUser,
					replySource: reply1,
					content: "Hello, Third World!"
				)

				modelContext.insert(reply2)

				try! modelContext.save()

				_ = try await self.apiClient.auth.signIn(username: "capturecontext", password: "psswrd").get()
				let tweets = try await self.apiClient.feed.fetchTweets(page: 0, limit: 3).get()

				callback(Store(
					initialState: MainFeature.State(
						feed: .init(
							feed: .init(
								list: .init(
									tweets: .init(
										uncheckedUniqueElements:
											tweets.map { $0.convert(to: .tweetFeature) }
									)
								)
							)
						),
						profile: .init(),
						selectedTab: .feed
					),
					reducer: {
						MainFeature()
							._printChanges()
					}
				))
			} catch {
				print(error)
			}
		}
	}

	var store: StoreOf<MainFeature>?

	public func scene(
		_ scene: UIScene,
		willConnectTo session: UISceneSession,
		options connectionOptions: UIScene.ConnectionOptions
	) {
		guard let scene = scene as? UIWindowScene else { return }
		let controller = MainViewController()

		setupStore { store in
			self.store = store
			controller.setStore(store)
		}

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


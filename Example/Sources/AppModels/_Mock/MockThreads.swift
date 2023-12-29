//import LocalExtensions
//
//extension TweetModel {
//	public static func mockReplies(
//	 for id: USID
// ) -> IdentifiedArrayOf<TweetModel> {
//	 mockTweets[id: id].map { source in
//		 mockTweets.filter { $0.replyTo == source.id }
//	 }.or([])
// }
//
//	public static let mockTweets: IdentifiedArrayOf<TweetModel> = .init(uniqueElements: [
//		TweetModel.mock(
//			author: UserModel.mock(username: "JohnDoe"),
//			text: "Hello, world!"
//		).withReplies { model in
//			TweetModel.mock(
//				author: UserModel.mock(username: "JaneDoe"),
//				replyTo: model.id,
//				text: "Hello, John!"
//			)
//			TweetModel.mock(
//				author: UserModel.mock(username: "Alice"),
//				replyTo: model.id,
//				text: "Nice weather today."
//			)
//			TweetModel.mock(
//				author: UserModel.mock(username: "Bob"),
//				replyTo: model.id,
//				text: "Agree with you, Alice."
//			)
//			TweetModel.mock(
//				author: UserModel.mock(username: "Charlie"),
//				replyTo: model.id,
//				text: "Looking forward to the weekend."
//			).withReplies { model in
//				TweetModel.mock(
//					author: UserModel.mock(username: "Emma"),
//					replyTo: model.id,
//					text: "Me too, Charlie!"
//				)
//				TweetModel.mock(
//					author: UserModel.mock(username: "Oliver"),
//					replyTo: model.id,
//					text: "Same here."
//				)
//			}
//			TweetModel.mock(
//				author: UserModel.mock(username: "Sophia"),
//				replyTo: model.id,
//				text: "Have a nice day, everyone!"
//			)
//		},
//		TweetModel.mock(
//			author: UserModel.mock(username: "Mike"),
//			text: "Let's discuss our favorite movies!"
//		).withReplies { model in
//			TweetModel.mock(
//				author: UserModel.mock(username: "Lucy"),
//				replyTo: model.id,
//				text: "I love Titanic."
//			)
//			TweetModel.mock(
//				author: UserModel.mock(username: "Sam"),
//				replyTo: model.id,
//				text: "The Shawshank Redemption is the best!"
//			).withReplies { innerModel in
//				TweetModel.mock(
//					author: UserModel.mock(username: "Tom"),
//					replyTo: innerModel.id,
//					text: "Indeed, it's a touching story."
//				)
//				TweetModel.mock(
//					author: UserModel.mock(username: "EmmaJ"),
//					replyTo: innerModel.id,
//					text: "I was moved to tears by that movie."
//				)
//			}
//		},
//		TweetModel.mock(
//			author: UserModel.mock(username: "Olivia"),
//			text: "Crowd-sourcing the best books!"
//		).withReplies { model in
//			for i in 1...10 {
//				TweetModel.mock(
//					author: UserModel.mock(username: "User\(i)"),
//					replyTo: model.id,
//					text: "Book suggestion #\(i)."
//				)
//			}
//		},
//		TweetModel.mock(
//			author: UserModel.mock(username: "Harry"),
//			text: "Who's following the basketball championship?"
//		).withReplies { model in
//			TweetModel.mock(
//				author: UserModel.mock(username: "Nina"),
//				replyTo: model.id,
//				text: "Wouldn't miss it for the world!"
//			).withReplies { innerModel in
//				TweetModel.mock(
//					author: UserModel.mock(username: "Rihanna"),
//					replyTo: innerModel.id,
//					text: "Same here!"
//				).withReplies { innerMostModel in
//					TweetModel.mock(
//						author: UserModel.mock(username: "George"),
//						replyTo: innerMostModel.id,
//						text: "Go Lakers!"
//					)
//				}
//			}
//			TweetModel.mock(
//				author: UserModel.mock(username: "Drake"),
//				replyTo: model.id,
//				text: "I'll be at the final game!"
//			)
//		},
//		TweetModel.mock(
//			author: UserModel.mock(username: "ElonMusk"),
//			text: "Exploring Mars: What are the most significant challenges we're looking to overcome?"
//		).withReplies { model in
//			TweetModel.mock(
//				author: UserModel.mock(username: "AstroJane"),
//				replyTo: model.id,
//				text: "I believe overcoming the harsh weather conditions is a major challenge."
//			).withReplies { innerModel in
//				TweetModel.mock(
//					author: UserModel.mock(username: "ScienceMike"),
//					replyTo: innerModel.id,
//					text: "Absolutely, the extreme cold and dust storms are definitely obstacles."
//				)
//			}
//		},
//		TweetModel.mock(
//			author: UserModel.mock(username: "BillGates"),
//			text: "How can technology further help in improving education globally?"
//		).withReplies { model in
//			for i in 1...5 {
//				TweetModel.mock(
//					author: UserModel.mock(username: "EdTechExpert\(i)"),
//					replyTo: model.id,
//					text: "I think technology #\(i) would greatly improve global education."
//				)
//			}
//		},
//		TweetModel.mock(
//			author: UserModel.mock(username: "TaylorSwift"),
//			text: "New album release next month! What themes do you guys hope to hear?"
//		).withReplies { model in
//			TweetModel.mock(
//				author: UserModel.mock(username: "Fan1"),
//				replyTo: model.id,
//				text: "I hope to hear some songs about moving on and finding oneself."
//			)
//			TweetModel.mock(
//				author: UserModel.mock(username: "Fan2"),
//				replyTo: model.id,
//				text: "Can't wait for love songs!"
//			).withReplies { innerModel in
//				TweetModel.mock(
//					author: UserModel.mock(username: "Fan3"),
//					replyTo: innerModel.id,
//					text: "Yes, her love songs always hit differently."
//				)
//			}
//		},
//		TweetModel.mock(
//			author: UserModel.mock(username: "ChefGordon"),
//			text: "What's your all-time favorite recipe?"
//		).withReplies { model in
//			TweetModel.mock(
//				author: UserModel.mock(username: "FoodieSam"),
//				replyTo: model.id,
//				text: "I love a classic spaghetti carbonara. Simple, yet so delicious."
//			)
//			TweetModel.mock(
//				author: UserModel.mock(username: "CulinaryMaster"),
//				replyTo: model.id,
//				text: "Can't go wrong with a perfectly cooked steak."
//			)
//		},
//		TweetModel.mock(
//			author: UserModel.mock(username: "CryptoExpert"),
//			text: "What's everyone's prediction for Bitcoin for the next year?"
//		).withReplies { model in
//			TweetModel.mock(
//				author: UserModel.mock(username: "BitcoinBull"),
//				replyTo: model.id,
//				text: "I foresee a great year ahead for Bitcoin. Hold on to what you've got!"
//			).withReplies { innerModel in
//				TweetModel.mock(
//					author: UserModel.mock(username: "CryptoSkeptic"),
//					replyTo: innerModel.id,
//					text: "I'm not so certain. It's wise to diversify and not put all your eggs in one basket."
//				)
//			}
//		}
//	].flatMap { $0 })
//}

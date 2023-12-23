import LocalExtensions

extension TweetModel {
	public static func mockReplies(
	 for id: UUID
 ) -> IdentifiedArrayOf<TweetModel> {
	 mockTweets[id: id].map { source in
		 mockTweets.filter { $0.replyTo == source.id }
	 }.or([])
 }

	public static let mockTweets: IdentifiedArrayOf<TweetModel> = .init(uniqueElements: [
		TweetModel.mock(
			authorID: UserModel.mock(username: "JohnDoe").id,
			text: "Hello, world!"
		).withReplies { model in
			TweetModel.mock(
				authorID: UserModel.mock(username: "JaneDoe").id,
				replyTo: model.id,
				text: "Hello, John!"
			)
			TweetModel.mock(
				authorID: UserModel.mock(username: "Alice").id,
				replyTo: model.id,
				text: "Nice weather today."
			)
			TweetModel.mock(
				authorID: UserModel.mock(username: "Bob").id,
				replyTo: model.id,
				text: "Agree with you, Alice."
			)
			TweetModel.mock(
				authorID: UserModel.mock(username: "Charlie").id,
				replyTo: model.id,
				text: "Looking forward to the weekend."
			).withReplies { model in
				TweetModel.mock(
					authorID: UserModel.mock(username: "Emma").id,
					replyTo: model.id,
					text: "Me too, Charlie!"
				)
				TweetModel.mock(
					authorID: UserModel.mock(username: "Oliver").id,
					replyTo: model.id,
					text: "Same here."
				)
			}
			TweetModel.mock(
				authorID: UserModel.mock(username: "Sophia").id,
				replyTo: model.id,
				text: "Have a nice day, everyone!"
			)
		},
		TweetModel.mock(
			authorID: UserModel.mock(username: "Mike").id,
			text: "Let's discuss our favorite movies!"
		).withReplies { model in
			TweetModel.mock(
				authorID: UserModel.mock(username: "Lucy").id,
				replyTo: model.id,
				text: "I love Titanic."
			)
			TweetModel.mock(
				authorID: UserModel.mock(username: "Sam").id,
				replyTo: model.id,
				text: "The Shawshank Redemption is the best!"
			).withReplies { innerModel in
				TweetModel.mock(
					authorID: UserModel.mock(username: "Tom").id,
					replyTo: innerModel.id,
					text: "Indeed, it's a touching story."
				)
				TweetModel.mock(
					authorID: UserModel.mock(username: "EmmaJ").id,
					replyTo: innerModel.id,
					text: "I was moved to tears by that movie."
				)
			}
		},
		TweetModel.mock(
			authorID: UserModel.mock(username: "Olivia").id,
			text: "Crowd-sourcing the best books!"
		).withReplies { model in
			for i in 1...10 {
				TweetModel.mock(
					authorID: UserModel.mock(username: "User\(i)").id,
					replyTo: model.id,
					text: "Book suggestion #\(i)."
				)
			}
		},
		TweetModel.mock(
			authorID: UserModel.mock(username: "Harry").id,
			text: "Who's following the basketball championship?"
		).withReplies { model in
			TweetModel.mock(
				authorID: UserModel.mock(username: "Nina").id,
				replyTo: model.id,
				text: "Wouldn't miss it for the world!"
			).withReplies { innerModel in
				TweetModel.mock(
					authorID: UserModel.mock(username: "Rihanna").id,
					replyTo: innerModel.id,
					text: "Same here!"
				).withReplies { innerMostModel in
					TweetModel.mock(
						authorID: UserModel.mock(username: "George").id,
						replyTo: innerMostModel.id,
						text: "Go Lakers!"
					)
				}
			}
			TweetModel.mock(
				authorID: UserModel.mock(username: "Drake").id,
				replyTo: model.id,
				text: "I'll be at the final game!"
			)
		},
		TweetModel.mock(
			authorID: UserModel.mock(username: "ElonMusk").id,
			text: "Exploring Mars: What are the most significant challenges we're looking to overcome?"
		).withReplies { model in
			TweetModel.mock(
				authorID: UserModel.mock(username: "AstroJane").id,
				replyTo: model.id,
				text: "I believe overcoming the harsh weather conditions is a major challenge."
			).withReplies { innerModel in
				TweetModel.mock(
					authorID: UserModel.mock(username: "ScienceMike").id,
					replyTo: innerModel.id,
					text: "Absolutely, the extreme cold and dust storms are definitely obstacles."
				)
			}
		},
		TweetModel.mock(
			authorID: UserModel.mock(username: "BillGates").id,
			text: "How can technology further help in improving education globally?"
		).withReplies { model in
			for i in 1...5 {
				TweetModel.mock(
					authorID: UserModel.mock(username: "EdTechExpert\(i)").id,
					replyTo: model.id,
					text: "I think technology #\(i) would greatly improve global education."
				)
			}
		},
		TweetModel.mock(
			authorID: UserModel.mock(username: "TaylorSwift").id,
			text: "New album release next month! What themes do you guys hope to hear?"
		).withReplies { model in
			TweetModel.mock(
				authorID: UserModel.mock(username: "Fan1").id,
				replyTo: model.id,
				text: "I hope to hear some songs about moving on and finding oneself."
			)
			TweetModel.mock(
				authorID: UserModel.mock(username: "Fan2").id,
				replyTo: model.id,
				text: "Can't wait for love songs!"
			).withReplies { innerModel in
				TweetModel.mock(
					authorID: UserModel.mock(username: "Fan3").id,
					replyTo: innerModel.id,
					text: "Yes, her love songs always hit differently."
				)
			}
		},
		TweetModel.mock(
			authorID: UserModel.mock(username: "ChefGordon").id,
			text: "What's your all-time favorite recipe?"
		).withReplies { model in
			TweetModel.mock(
				authorID: UserModel.mock(username: "FoodieSam").id,
				replyTo: model.id,
				text: "I love a classic spaghetti carbonara. Simple, yet so delicious."
			)
			TweetModel.mock(
				authorID: UserModel.mock(username: "CulinaryMaster").id,
				replyTo: model.id,
				text: "Can't go wrong with a perfectly cooked steak."
			)
		},
		TweetModel.mock(
			authorID: UserModel.mock(username: "CryptoExpert").id,
			text: "What's everyone's prediction for Bitcoin for the next year?"
		).withReplies { model in
			TweetModel.mock(
				authorID: UserModel.mock(username: "BitcoinBull").id,
				replyTo: model.id,
				text: "I foresee a great year ahead for Bitcoin. Hold on to what you've got!"
			).withReplies { innerModel in
				TweetModel.mock(
					authorID: UserModel.mock(username: "CryptoSkeptic").id,
					replyTo: innerModel.id,
					text: "I'm not so certain. It's wise to diversify and not put all your eggs in one basket."
				)
			}
		}
	].flatMap { $0 })
}

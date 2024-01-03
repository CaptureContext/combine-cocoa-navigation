test:
	xcodebuild \
		-scheme "combine-cocoa-navigation" \
		-destination platform="iOS Simulator,name=iPhone 15 Pro,OS=17.0" \
		test | xcpretty && exit 0

test-macro:
	swift test --filter CombineNavigationMacrosTests

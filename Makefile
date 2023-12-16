test:
	xcodebuild \
		-scheme CombineNavigation \
		-destination platform="iOS Simulator,name=iPhone 15 Pro,OS=17.0" \
		test | xcpretty && exit 0

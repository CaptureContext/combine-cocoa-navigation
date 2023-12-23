import AppFeature
import AppUI

let delegate = AppDelegate()
UIApplication.shared.delegate = delegate

_ = UIApplicationMain(
	CommandLine.argc,
	CommandLine.unsafeArgv,
	nil,
	nil
)

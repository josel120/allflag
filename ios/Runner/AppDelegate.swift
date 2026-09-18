import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var flagModeChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "com.allflag.allflag/flag_mode",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    flagModeChannel = channel
    channel.setMethodCallHandler { call, result in
      guard call.method == "setFlagMode" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let active = call.arguments as? Bool else {
        result(FlutterError(code: "invalid_argument", message: "Expected a boolean", details: nil))
        return
      }
      // The main-thread channel only disables idle sleep while this app is active.
      // Flutter's SystemChrome handles status bar and home-indicator presentation.
      let keepAwake = active && UIApplication.shared.applicationState == .active
      if UIApplication.shared.isIdleTimerDisabled != keepAwake {
        UIApplication.shared.isIdleTimerDisabled = keepAwake
      }
      result(nil)
    }
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    application.isIdleTimerDisabled = false
    super.applicationWillTerminate(application)
  }
}

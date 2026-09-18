import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func sceneWillResignActive(_ scene: UIScene) {
    // Native fail-safe even if Dart is suspended before its lifecycle cleanup runs.
    UIApplication.shared.isIdleTimerDisabled = false
    super.sceneWillResignActive(scene)
  }

  override func sceneDidEnterBackground(_ scene: UIScene) {
    UIApplication.shared.isIdleTimerDisabled = false
    super.sceneDidEnterBackground(scene)
  }

  override func sceneDidDisconnect(_ scene: UIScene) {
    UIApplication.shared.isIdleTimerDisabled = false
    super.sceneDidDisconnect(scene)
  }
}

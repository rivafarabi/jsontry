import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  /// Captured from `application(_:openFile:)` before the launch channel exists.
  static var launchFilePath: String?

  /// Set by MainFlutterWindow once the FlutterViewController/engine exists.
  static var launchChannel: FlutterMethodChannel?

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    if let channel = AppDelegate.launchChannel {
      channel.invokeMethod("openFile", arguments: filename)
    } else {
      AppDelegate.launchFilePath = filename
    }
    return true
  }
}

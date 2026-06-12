import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    let launchChannel = FlutterMethodChannel(
      name: "com.rivafarabi.jsontry/launch",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    launchChannel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "getInitialFile":
        result(AppDelegate.launchFilePath)
        AppDelegate.launchFilePath = nil
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    AppDelegate.launchChannel = launchChannel

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}

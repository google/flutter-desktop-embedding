import FlutterMacOS
import Cocoa

public class SwiftExamplePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "example_plugin", binaryMessenger: registrar.messenger)
    let instance = SwiftExamplePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if (call.method == "getPlatformVersion") {
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    } else {
      result(FlutterMethodNotImplemented);
    }
  }
}

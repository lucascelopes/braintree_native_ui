import Flutter
import UIKit

public class BraintreeCustomUiPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "braintree_custom_ui", binaryMessenger: registrar.messenger())
    let instance = BraintreeCustomUiPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "ping": result("pong-ios")
    default: result(FlutterMethodNotImplemented)
    }
  }
}

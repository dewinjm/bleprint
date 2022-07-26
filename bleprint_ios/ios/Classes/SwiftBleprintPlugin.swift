// Copyright (c) 2022 dewin
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import Flutter
import UIKit

public class SwiftBleprintPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "bleprint_ios", binaryMessenger: registrar.messenger())
    let instance = SwiftBleprintPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
        case "getPlatformName":
            result("iOS")
        default:
            result(FlutterMethodNotImplemented)
    }
  }
}

// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import FlutterMacOS
import Foundation

public class SharedPreferencesPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "plugins.flutter.io/shared_preferences",
      binaryMessenger: registrar.messenger)
    let instance = SharedPreferencesPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let method = call.method
    if method == "getAll" {
      result(getAllPrefs())
    } else if method == "setBool" ||
              method == "setInt" ||
              method == "setInt" ||
              method == "setDouble" ||
              method == "setString" ||
              method == "setStringList" {
      let arguments = call.arguments as! [String: Any]
      let key = arguments["key"] as! String
      UserDefaults.standard.set(arguments["value"], forKey: key)
      result(true)
    } else if method == "commit" {
      // UserDefaults does not need to be synchronized.
      result(true)
    } else if method == "remove" {
      let arguments = call.arguments as! [String: Any]
      let key = arguments["key"] as! String
      UserDefaults.standard.removeObject(forKey: key)
      result(true)
    } else if method == "clear" {
      let defaults = UserDefaults.standard
      for (key, _) in getAllPrefs() {
        defaults.removeObject(forKey: key)
      }
      result(true)
    } else {
      result(FlutterMethodNotImplemented)
    }
  }
}

/// Returns all preferences stored by this plugin.
private func getAllPrefs() -> [String: Any] {
  var filteredPrefs: [String: Any] = [:]
  if let appDomain = Bundle.main.bundleIdentifier,
     let prefs = UserDefaults.standard.persistentDomain(forName: appDomain) {
    for (key, value) in prefs where key.hasPrefix("flutter.") {
      filteredPrefs[key] = value
    }
  }
  return filteredPrefs
}

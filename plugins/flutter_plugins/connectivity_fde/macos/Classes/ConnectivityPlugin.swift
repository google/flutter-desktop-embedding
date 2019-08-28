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

import Cocoa
import CoreWLAN
import FlutterMacOS
import Reachability
import SystemConfiguration.CaptiveNetwork

public class ConnectivityPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  var _reach: Reachability?
  var _eventSink: FlutterEventSink?
  var _cwinterface: CWInterface?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "plugins.flutter.io/connectivity", binaryMessenger: registrar.messenger)

    let instance = ConnectivityPlugin()
    instance._cwinterface = CWWiFiClient.shared().interface()!

    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "check" {
      result(statusFromReachability(reachability: Reachability.forInternetConnection()))
    } else if call.method == "wifiName" {
      result(_cwinterface!.ssid()!)
    } else if call.method == "wifiBSSID" {
      result(_cwinterface!.bssid()!)
    } else if call.method == "wifiIPAddress" {
      result(getWiFiIP())
    } else {
      result(FlutterMethodNotImplemented)
    }
  }

  func getWiFiIP() -> String? {
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    let result = getifaddrs(&ifaddr)

    if result == 0 {
      guard let firstAddr = ifaddr else { return nil }

      for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
        let name = String(cString: ptr.pointee.ifa_name)
        let addr = ptr.pointee.ifa_addr.pointee

        if addr.sa_family == UInt8(AF_INET), name == "en0" {
          var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
          if getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                   nil, socklen_t(0), NI_NUMERICHOST) == 0 {
            let address = String(cString: hostname)
            freeifaddrs(ifaddr)
            return address
          }
        }
      }
    }

    freeifaddrs(ifaddr)

    return nil
  }

  public func statusFromReachability(reachability: Reachability) -> String {
    if reachability.isReachableViaWiFi() {
      return "wifi"
    }

    if reachability.isReachableViaWWAN() {
      return "mobile"
    }

    return "none"
  }

  public func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    _reach = Reachability.forInternetConnection()
    _reach!.reachableOnWWAN = false
    _eventSink = events

    NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged), name: NSNotification.Name.reachabilityChanged, object: nil)

    return nil
  }

  @objc func reachabilityChanged(notification: NSNotification) {
    let reach = notification.object
    let reachability = statusFromReachability(reachability: reach as! Reachability)
    (_eventSink as! FlutterEventSink)(reachability)
  }

  public func onCancel(withArguments _: Any?) -> FlutterError? {
    _reach?.stopNotifier()
    NotificationCenter.default.removeObserver(self)
    _eventSink = nil
    return nil
  }
}

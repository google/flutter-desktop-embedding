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
#include "custom_cursor.h"

#include <windows.h>

#include <VersionHelpers.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>
#include <flutter/standard_method_codec.h>
#include <memory>
#include <sstream>

namespace {

class CustomCursor : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrar *registrar);

  // Creates a plugin that communicates on the given channel.
  CustomCursor(
      std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel);

  virtual ~CustomCursor();

 private:
  // Called when a method is called on |channel_|;
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // The MethodChannel used for communication with the Flutter engine.
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

// static
void CustomCursor::RegisterWithRegistrar(flutter::PluginRegistrar *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "custom_cursor",
          &flutter::StandardMethodCodec::GetInstance());
  auto *channel_pointer = channel.get();

  auto plugin = std::make_unique<CustomCursor>(std::move(channel));

  channel_pointer->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

CustomCursor::CustomCursor(
    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel)
    : channel_(std::move(channel)) {}

CustomCursor::~CustomCursor(){};

void CustomCursor::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
      std::string method = method_call.method_name();
  if (method.compare("hideCursor") == 0) {
    while (ShowCursor(false) >= 0) {
    }
    flutter::EncodableValue response(true);
    result->Success(&response);
  } else if (method.compare("showCursor") == 0) {
    while (ShowCursor(true) >= 0) {
    }
    flutter::EncodableValue response(true);
    result->Success(&response);
  } else if (method.compare("resetCursor") == 0) {
    HCURSOR cursor = LoadCursor(0, IDC_ARROW);
    SetCursor(cursor);
    flutter::EncodableValue response(true);
    result->Success(&response);
  } else if (method.compare("setCursor") == 0) {
    const flutter::EncodableValue *args = method_call.arguments();
    const flutter::EncodableMap &map = args->MapValue();
    bool update = map.at(flutter::EncodableValue("update")).BoolValue();
    std::string type = map.at(flutter::EncodableValue("type")).StringValue();
    HCURSOR cursor;
    if (type.compare("appStart") == 0) {
      cursor = LoadCursor(0, IDC_APPSTARTING);
    } else if (type.compare("arrow") == 0) {
      cursor = LoadCursor(0, IDC_ARROW);
    } else if (type.compare("cross") == 0) {
      cursor = LoadCursor(0, IDC_CROSS);
    } else if (type.compare("hand") == 0) {
      cursor = LoadCursor(0, IDC_HAND);
    } else if (type.compare("help") == 0) {
      cursor = LoadCursor(0, IDC_HELP);
    } else if (type.compare("iBeam") == 0) {
      cursor = LoadCursor(0, IDC_IBEAM);
    } else if (type.compare("no") == 0) {
      cursor = LoadCursor(0, IDC_NO);
    } else if (type.compare("resizeAll") == 0) {
      cursor = LoadCursor(0, IDC_SIZEALL);
    } else if (type.compare("resizeNESW") == 0) {
      cursor = LoadCursor(0, IDC_SIZENESW);
    } else if (type.compare("resizeNS") == 0) {
      cursor = LoadCursor(0, IDC_SIZENS);
    } else if (type.compare("resizeNWSE") == 0) {
      cursor = LoadCursor(0, IDC_SIZENWSE);
    } else if (type.compare("resizeWE") == 0) {
      cursor = LoadCursor(0, IDC_SIZEWE);
    } else if (type.compare("upArrow") == 0) {
      cursor = LoadCursor(0, IDC_UPARROW);
    } else if (type.compare("wait") == 0) {
      cursor = LoadCursor(0, IDC_WAIT);
    } else {
      cursor = LoadCursor(0, IDC_ARROW);
    }
    SetCursor(cursor);
    flutter::EncodableValue response(true);
    result->Success(&response);
  } else {
    result->NotImplemented();
  }
}

}  // namespace

void CustomCursorRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  // The plugin registrar owns the plugin, registered callbacks, etc., so must
  // remain valid for the life of the application.
  static auto *plugin_registrar = new flutter::PluginRegistrar(registrar);

  CustomCursor::RegisterWithRegistrar(plugin_registrar);
}

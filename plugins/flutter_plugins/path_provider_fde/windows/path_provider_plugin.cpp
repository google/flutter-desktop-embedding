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
#include "path_provider_plugin.h"

#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>
#include <flutter/standard_method_codec.h>
#include <codecvt>
#include <memory>
#include <string>

namespace {

using flutter::EncodableValue;

class PathProviderPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrar *registrar);

  virtual ~PathProviderPlugin();

 private:
  PathProviderPlugin();

  // Called when a method is called on plugin channel;
  void HandleMethodCall(
      const flutter::MethodCall<EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<EncodableValue>> result);
};

// static
void PathProviderPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrar *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      registrar->messenger(), "plugins.flutter.io/path_provider",
      &flutter::StandardMethodCodec::GetInstance());

  // Uses new instead of make_unique due to private constructor.
  std::unique_ptr<PathProviderPlugin> plugin(new PathProviderPlugin());

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

PathProviderPlugin::PathProviderPlugin() = default;

PathProviderPlugin::~PathProviderPlugin() = default;

void PathProviderPlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  if (method_call.method_name().compare("getTemporaryDirectory") == 0) {
    TCHAR path_buffer[MAX_PATH];
    UINT length = GetTempPath(MAX_PATH, path_buffer);
    if (length > 0 && length <= MAX_PATH) {
      std::wstring_convert<std::codecvt_utf8<wchar_t>> wide_to_utf8;
      std::string temp_path = wide_to_utf8.to_bytes(path_buffer);
      flutter::EncodableValue response(temp_path.c_str());
      result->Success(&response);
    } else {
      result->Error("Unable to get path");
    }
  } else if (method_call.method_name().compare("getApplicationSupportDirectory") == 0) {
    result->NotImplemented();
  } else if (method_call.method_name().compare("getApplicationDocumentsDirectory") == 0) {
    result->NotImplemented();
  } else {
    result->NotImplemented();
  }
}

}  // namespace

void PathProviderPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  // The plugin registrar owns the plugin, registered callbacks, etc., so must
  // remain valid for the life of the application.
  static auto *plugin_registrar = new flutter::PluginRegistrar(registrar);
  PathProviderPlugin::RegisterWithRegistrar(plugin_registrar);
}

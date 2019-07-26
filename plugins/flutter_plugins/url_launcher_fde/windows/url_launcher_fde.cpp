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
#include "url_launcher_fde.h"

#include <windows.h>

#include <VersionHelpers.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>
#include <flutter/standard_method_codec.h>
#include <memory>
#include <sstream>

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;

class UrlLauncherPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrar *registrar);

  virtual ~UrlLauncherPlugin();

 private:
  UrlLauncherPlugin();

  // Called when a method is called on plugin channel;
  void HandleMethodCall(
      const flutter::MethodCall<EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<EncodableValue>> result);
};

// static
void UrlLauncherPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrar *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      registrar->messenger(), "plugins.flutter.io/url_launcher",
      &flutter::StandardMethodCodec::GetInstance());

  // Uses new instead of make_unique due to private constructor.
  std::unique_ptr<UrlLauncherPlugin> plugin(new UrlLauncherPlugin());

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

UrlLauncherPlugin::UrlLauncherPlugin() = default;

UrlLauncherPlugin::~UrlLauncherPlugin() = default;

void UrlLauncherPlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  if (method_call.method_name().compare("launch") == 0) {
    std::string url;
    if (method_call.arguments() && method_call.arguments()->IsMap()) {
      const EncodableMap &arguments = method_call.arguments()->MapValue();
      auto url_it = arguments.find(EncodableValue("url"));
      if (url_it != arguments.end()) {
        url = url_it->second.StringValue();
      }
    }
    if (url.empty()) {
      result->Error("argument_error", "No URL provided");
      return;
    }

    // launch a URL on Windows
    size_t size = url.length() + 1;
    std::wstring wurl;
    wurl.reserve(size);
    size_t outSize;
    mbstowcs_s(&outSize, &wurl[0], size, url.c_str(), size - 1);

#pragma warning(push)
#pragma warning(disable : 4311)  // warning C4311: 'type cast': pointer
                                 // truncation from 'HINSTANCE' to 'int'
#pragma warning(disable : 4302)  // warning C4302: 'type cast': truncation from
                                 // 'HINSTANCE' to 'int'
    int status =
        reinterpret_cast<int>(ShellExecute(NULL, TEXT("open"), wurl.c_str(), NULL, NULL, SW_SHOWNORMAL));
#pragma warning(pop)

    if (status <= 32) {
      std::ostringstream error_message;
      error_message << "Failed to open " << url << ": ShellExecute error code "
                    << status;
      result->Error("open_error", error_message.str());
      return;
    }
    result->Success();
  } else {
    result->NotImplemented();
  }
}

}  // namespace

void UrlLauncherRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  // The plugin registrar owns the plugin, registered callbacks, etc., so must
  // remain valid for the life of the application.
  static auto *plugin_registrar = new flutter::PluginRegistrar(registrar);
  UrlLauncherPlugin::RegisterWithRegistrar(plugin_registrar);
}

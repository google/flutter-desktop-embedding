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
#include "include/url_launcher_fde/url_launcher_plugin.h"

#include <Windows.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <string>

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;

// Converts the given UTF-8 string to UTF-16.
std::wstring Utf16FromUtf8(const std::string &utf8_string) {
  if (utf8_string.empty()) {
    return std::wstring();
  }
  int target_length =
      ::MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8_string.data(),
                            static_cast<int>(utf8_string.length()), nullptr, 0);
  if (target_length == 0) {
    return std::wstring();
  }
  std::wstring utf16_string;
  utf16_string.resize(target_length);
  int converted_length =
      ::MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8_string.data(),
                            static_cast<int>(utf8_string.length()),
                            utf16_string.data(), target_length);
  if (converted_length == 0) {
    return std::wstring();
  }
  return utf16_string;
}

// Returns the URL argument from |method_call| if it is present, otherwise
// returns an empty string.
std::string GetUrlArgument(
    const flutter::MethodCall<EncodableValue> &method_call) {
  std::string url;
  const auto *arguments = std::get_if<EncodableMap>(method_call.arguments());
  if (arguments) {
    auto url_it = arguments->find(EncodableValue("url"));
    if (url_it != arguments->end()) {
      url = std::get<std::string>(url_it->second);
    }
  }
  return url;
}

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
    std::string url = GetUrlArgument(method_call);
    if (url.empty()) {
      result->Error("argument_error", "No URL provided");
      return;
    }
    std::wstring url_wide = Utf16FromUtf8(url);

    int status = static_cast<int>(reinterpret_cast<INT_PTR>(
        ::ShellExecute(nullptr, TEXT("open"), url_wide.c_str(), nullptr,
                       nullptr, SW_SHOWNORMAL)));

    if (status <= 32) {
      std::ostringstream error_message;
      error_message << "Failed to open " << url << ": ShellExecute error code "
                    << status;
      result->Error("open_error", error_message.str());
      return;
    }
    EncodableValue response(true);
    result->Success(&response);
  } else if (method_call.method_name().compare("canLaunch") == 0) {
    std::string url = GetUrlArgument(method_call);
    if (url.empty()) {
      result->Error("argument_error", "No URL provided");
      return;
    }

    bool can_launch = false;
    size_t separator_location = url.find(":");
    if (separator_location != std::string::npos) {
      std::wstring scheme = Utf16FromUtf8(url.substr(0, separator_location));
      HKEY key = nullptr;
      if (::RegOpenKeyEx(HKEY_CLASSES_ROOT, scheme.c_str(), 0, KEY_QUERY_VALUE,
                         &key) == ERROR_SUCCESS) {
        can_launch = ::RegQueryValueEx(key, L"URL Protocol", nullptr, nullptr,
                                       nullptr, nullptr) == ERROR_SUCCESS;
        ::RegCloseKey(key);
      }
    }
    EncodableValue response(can_launch);
    result->Success(&response);
  } else {
    result->NotImplemented();
  }
}

}  // namespace

void UrlLauncherPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  UrlLauncherPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

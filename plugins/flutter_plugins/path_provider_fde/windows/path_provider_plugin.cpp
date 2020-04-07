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

#include <ShlObj.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <codecvt>
#include <memory>
#include <sstream>
#include <string>

namespace {

using flutter::EncodableValue;

// Converts an null-terminated array of wchar_t's to a std::string.
std::string StdStringFromWideChars(wchar_t *wide_chars) {
  std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> wide_to_utf8;
  return wide_to_utf8.to_bytes(wide_chars);
}

// Gets the path to the given folder ID, without verifying that it exists,
// or an empty string on failure.
std::string GetFolderPath(REFKNOWNFOLDERID folder_id) {
  wchar_t *wide_path = nullptr;
  if (!SUCCEEDED(SHGetKnownFolderPath(folder_id, KF_FLAG_DONT_VERIFY, nullptr,
                                      &wide_path))) {
    return "";
  }
  std::string path = StdStringFromWideChars(wide_path);
  CoTaskMemFree(wide_path);
  return path;
}

// Returns the name of the executable, without the .exe extension, or an empty
// string on failure.
std::string GetExecutableName() {
  wchar_t buffer[MAX_PATH];
  if (GetModuleFileName(nullptr, buffer, MAX_PATH) == 0) {
    return "";
  }
  std::string executable_path = StdStringFromWideChars(buffer);
  size_t last_separator_position = executable_path.find_last_of('\\');
  std::string executable_name;
  if (last_separator_position == std::string::npos) {
    executable_name = executable_path;
  } else {
    executable_name = executable_path.substr(last_separator_position + 1);
  }
  // Strip the .exe extension, if present.
  std::string extension = ".exe";
  if (executable_name.compare(executable_name.size() - extension.size(),
                              extension.size(), extension) == 0) {
    executable_name =
        executable_name.substr(0, executable_name.size() - extension.size());
  }
  return executable_name;
}

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
    wchar_t path_buffer[MAX_PATH];
    DWORD length = GetTempPath(MAX_PATH, path_buffer);
    if (length == 0 || length > MAX_PATH) {
      result->Error("Unable to get temporary path");
      return;
    }
    std::string result_path = StdStringFromWideChars(path_buffer);
    flutter::EncodableValue response(result_path);
    result->Success(&response);
  } else if (method_call.method_name().compare(
                 "getApplicationSupportDirectory") == 0) {
    std::string path = GetFolderPath(FOLDERID_RoamingAppData);
    if (path.empty()) {
      result->Error("Unable to get application data path");
      return;
    }
    // Use the executable name as the subdirectory for now.
    std::string exe_name = GetExecutableName();
    if (exe_name.empty()) {
      result->Error("Unable to get exe name");
      return;
    }
    std::ostringstream response_stream;
    response_stream << path << "\\" << exe_name;
    flutter::EncodableValue response(response_stream.str());
    result->Success(&response);
  } else if (method_call.method_name().compare(
                 "getApplicationDocumentsDirectory") == 0) {
    std::string path = GetFolderPath(FOLDERID_Documents);
    if (path.empty()) {
      result->Error("Unable to get documents path");
      return;
    }
    flutter::EncodableValue response(path);
    result->Success(&response);
  } else {
    result->NotImplemented();
  }
}

}  // namespace

void PathProviderPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  PathProviderPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

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

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>
#include <flutter/standard_method_codec.h>

#include <fcntl.h>
#include <linux/limits.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <codecvt>
#include <cstring>
#include <iostream>
#include <locale>
#include <memory>
#include <sstream>
#include <string>
namespace {

using flutter::EncodableValue;

// Look here for GNOME based directories:
// https://askubuntu.com/questions/14535/whats-the-local-folder-for-in-my-home-directory

// Returns the name of the executable, without the .exe extension, or an empty
// string on failure.
std::string GetExecutableName() {
  const size_t bufSize = PATH_MAX + 1;
  char dirNameBuffer[bufSize];
  // Read the symbolic link '/proc/self/exe'.
  const char *linkName = "/proc/self/exe";
  const int ret = int(readlink(linkName, dirNameBuffer, bufSize - 1));
  if (ret < 0) {
    return "";
  }
  std::string dirName = std::string(dirNameBuffer);
  return dirName.substr(dirName.find_last_of("/") + 1);
}

void EnsureCreated(std::string path) {
  if (mkdir(path.c_str(), S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH) == -1) {
    if (errno == EEXIST) {
      // alredy exists
    } else {
      // something else
      std::cerr << "cannot create " << path << " error:" << strerror(errno)
                << std::endl;
    }
  }
}

class PathProviderPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrar *registrar);

  virtual ~PathProviderPlugin();

 private:
  PathProviderPlugin();
  std::string exe_name;
  std::string homedir_name;
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

PathProviderPlugin::PathProviderPlugin() {
  exe_name = GetExecutableName();
  const char *homedir;
  homedir = getenv("HOME");
  homedir_name = std::string(homedir);
}

PathProviderPlugin::~PathProviderPlugin() = default;

void PathProviderPlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  if (method_call.method_name().compare("getTemporaryDirectory") == 0) {
    std::string result_path = "/tmp";
    flutter::EncodableValue response(result_path);
    result->Success(&response);
  } else if (method_call.method_name().compare(
                 "getApplicationSupportDirectory") == 0) {
    if (homedir_name.empty()) {
      result->Error("Unable to get usr home directory");
      return;
    }
    // Use the executable name as the subdirectory for now.
    if (exe_name.empty()) {
      result->Error("Unable to get exe name");
      return;
    }
    std::ostringstream response_stream;
    response_stream << homedir_name << "/.cache/" << exe_name;
    EnsureCreated(response_stream.str());
    flutter::EncodableValue response(response_stream.str());
    result->Success(&response);
  } else if (method_call.method_name().compare(
                 "getApplicationDocumentsDirectory") == 0) {
    if (homedir_name.empty()) {
      result->Error("Unable to get usr home directory");
      return;
    }
    // Use the executable name as the subdirectory for now.
    if (exe_name.empty()) {
      result->Error("Unable to get exe name");
      return;
    }
    std::ostringstream response_stream;
    response_stream << homedir_name << "/.local/share/" << exe_name;
    EnsureCreated(response_stream.str());
    flutter::EncodableValue response(response_stream.str());
    result->Success(&response);
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

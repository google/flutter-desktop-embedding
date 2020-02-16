// Copyright 2020 Google LLC
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
#include <flutter/plugin_registrar_glfw.h>
#include <flutter/standard_method_codec.h>

#include <fcntl.h>
#include <linux/limits.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <codecvt>
#include <cstring>
#include <iostream>
// #include <locale>
#include <memory>
#include <sstream>
#include <string>

namespace {

using flutter::EncodableValue;

// Look here for GNOME based directories:
// https://askubuntu.com/questions/14535/whats-the-local-folder-for-in-my-home-directory

// Returns the name of the directory containing this executable, or an empty
// string if the directory cannot be found.
std::string GetExecutableName() {
  char buffer[PATH_MAX + 1];
  ssize_t length = readlink("/proc/self/exe", buffer, sizeof(buffer));
  if (length > PATH_MAX) {
    std::cerr << "Couldn't locate executable" << std::endl;
    return "";
  }
  std::string executable_path(buffer, length);
  size_t last_separator_position = executable_path.find_last_of('/');
  if (last_separator_position == std::string::npos) {
    std::cerr << "Unabled to find parent directory of " << executable_path
              << std::endl;
    return "";
  }
  return executable_path.substr(last_separator_position);
}

// Tries to create the directory of path, returns true if the directory
// was successfully created or was already created and false if the directory
// still does not exist
bool EnsureCreated(std::string path) {
  if (mkdir(path.c_str(), S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH) == -1) {
    if (errno != EEXIST) {
      // An error occurred that wasn't just the path not existing
      std::cerr << "Cannot create " << path << " error:" << strerror(errno)
                << std::endl;
      return false;
    }
  }
  return true;
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
    flutter::EncodableValue response("/tmp");
    result->Success(&response);
  } else if (method_call.method_name().compare(
                 "getApplicationSupportDirectory") == 0) {
    // Use the executable name as the subdirectory for now.
    std::string exe_name = GetExecutableName();
    if (exe_name.empty()) {
      result->Error("Unable to get application name");
      return;
    }
    // Get user defined data home directory
    const char *xdg_home = getenv("XDG_DATA_HOME");
    std::ostringstream response_stream;
    // Defaults to XDG default data home directory
    if (xdg_home == NULL) {
      response_stream << getenv("HOME") << "/.local/share/" << exe_name;
    } else {
      std::string xdg_home_string(xdg_home);
      // Need to ensure final forward slash so we can append the exe_name
      if (xdg_home_string.back() != '/') {
        xdg_home_string.push_back('/');
      }
      response_stream << xdg_home_string << exe_name;
    }
    // Ensure the directory exists or create it
    if (!EnsureCreated(response_stream.str())) {
      result->Error(
          "Unable to create a folder for the application in the ~/.local/share "
          "directory");
      return;
    }
    flutter::EncodableValue response(response_stream.str());
    result->Success(&response);
  } else if (method_call.method_name().compare(
                 "getApplicationDocumentsDirectory") == 0) {
    // Get user defined documents directory
    const char *xdg_documents_dir = getenv("XDG_DOCUMENTS_DIR");
    // Defaults to XDG default documents directory
    std::ostringstream response_stream;
    if (xdg_documents_dir == NULL) {
      response_stream << getenv("HOME") << "/Documents";
    } else {
      response_stream << xdg_documents_dir;
    }
    // Ensure the directory exists or create it
    if (!EnsureCreated(response_stream.str())) {
      result->Error("Unable to find or create user's Documents directory");
      return;
    }
    flutter::EncodableValue response(response_stream.str());
    result->Success(&response);
  } else {
    result->NotImplemented();
  }
}

}  // namespace

void PathProviderPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  // The plugin registrar wrappers owns the plugins, registered callbacks, etc.,
  // so must remain valid for the life of the application.
  static auto *plugin_registrars =
      new std::map<FlutterDesktopPluginRegistrarRef,
                   std::unique_ptr<flutter::PluginRegistrarGlfw>>;
  auto insert_result = plugin_registrars->emplace(
      registrar, std::make_unique<flutter::PluginRegistrarGlfw>(registrar));

  PathProviderPlugin::RegisterWithRegistrar(insert_result.first->second.get());
}

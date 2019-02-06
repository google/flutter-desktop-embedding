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

#ifndef LIBRARY_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_GLFW_FLUTTER_WINDOW_CONTROLLER_H_
#define LIBRARY_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_GLFW_FLUTTER_WINDOW_CONTROLLER_H_

#include <string>
#include <vector>

#ifdef USE_FDE_TREE_PATHS
#include <flutter_desktop_embedding_core/glfw/embedder.h>
#else
#include <flutter_desktop_embedding_core/embedder.h>
#endif

#ifdef USE_FDE_TREE_PATHS
#include "../plugin_registrar.h"
#else
#include "plugin_registrar.h"
#endif

namespace flutter_desktop_embedding {

class PluginHandler;

// A controller for a window displaying Flutter content.
//
// This is the primary wrapper class for the desktop embedding C API.
// If you use this class, you should not call any of the setup or teardown
// methods in embedder.h directly, as this class will do that internally.
//
// Note: This is an early implementation (using GLFW internally) which
// requires control of the application's event loop, and is thus useful
// primarily for building a simple one-window shell hosting a Flutter
// application. The final implementation and API will be very different.
class FlutterWindowController {
 public:
  // There must be only one instance of this class in an application at any
  // given time, as Flutter does not support multiple engines in one process,
  // or multiple views in one engine.
  explicit FlutterWindowController(std::string &icu_data_path);

  ~FlutterWindowController();

  // Creates and displays a window for displaying Flutter content.
  //
  // The |assets_path| is the path to the flutter_assets folder for the Flutter
  // application to be run. |icu_data_path| is the path to the icudtl.dat file
  // for the version of Flutter you are using.
  //
  // The |arguments| are passed to the Flutter engine. See:
  // https://github.com/flutter/engine/blob/master/shell/common/switches.h for
  // for details. Not all arguments will apply to embedding mode.
  //
  // Only one Flutter window can exist at a time; see constructor comment.
  bool CreateWindow(int width, int height, const std::string &assets_path,
                    const std::vector<std::string> &arguments);

  // Returns the PluginRegistrar to register a plugin with the given name.
  //
  // The name must be unique across the application, so the recommended approach
  // is to use the fully namespace-qualified name of the plugin class.
  PluginRegistrar *GetRegistrarForPlugin(const std::string &plugin_name);

  // Loops on Flutter window events until the window closes.
  void RunEventLoop();

 private:
  // The path to the ICU data file. Set at creation time since it is the same
  // for any window created.
  std::string icu_data_path_;

  // Whether or not FlutterEmbedderInit succeeded at creation time.
  bool init_succeeded_ = false;

  // The curent Flutter window, if any.
  FlutterWindowRef window_ = nullptr;

  // Plugin manager, to support GetRegistraryForPlugin.
  std::unique_ptr<PluginHandler> plugin_handler_;
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_GLFW_FLUTTER_WINDOW_CONTROLLER_H_

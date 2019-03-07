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

#ifdef USE_FDE_TREE_PATHS
#include "flutter_desktop_embedding/glfw/flutter_window_controller.h"
#else
#include "flutter_desktop_embedding/flutter_window_controller.h"
#endif

#include <algorithm>
#include <iostream>

namespace flutter_desktop_embedding {

FlutterWindowController::FlutterWindowController(std::string &icu_data_path)
    : icu_data_path_(icu_data_path) {
  init_succeeded_ = FlutterEmbedderInit();
}

FlutterWindowController::~FlutterWindowController() {
  if (init_succeeded_) {
    FlutterEmbedderTerminate();
  }
}

bool FlutterWindowController::CreateWindow(
    int width, int height, const std::string &assets_path,
    const std::vector<std::string> &arguments) {
  if (!init_succeeded_) {
    std::cerr << "Could not create window; FlutterEmbedderInit failed."
              << std::endl;
    return false;
  }

  if (window_) {
    std::cerr << "Only one Flutter window can exist at a time." << std::endl;
    return false;
  }

  std::vector<const char *> engine_arguments;
  std::transform(
      arguments.begin(), arguments.end(), std::back_inserter(engine_arguments),
      [](const std::string &arg) -> const char * { return arg.c_str(); });
  size_t arg_count = engine_arguments.size();

  window_ = FlutterEmbedderCreateWindow(
      width, height, assets_path.c_str(), icu_data_path_.c_str(),
      arg_count > 0 ? &engine_arguments[0] : nullptr, arg_count);
  if (!window_) {
    std::cerr << "Failed to create window." << std::endl;
    return false;
  }
  return true;
}

FlutterEmbedderPluginRegistrarRef
FlutterWindowController::GetRegistrarForPlugin(const std::string &plugin_name) {
  if (!window_) {
    std::cerr << "Cannot get plugin registrar without a window; call "
                 "CreateWindow first."
              << std::endl;
    return nullptr;
  }
  return FlutterEmbedderGetPluginRegistrar(window_, plugin_name.c_str());
}

void FlutterWindowController::SetHoverEnabled(bool enabled) {
  FlutterEmbedderSetHoverEnabled(window_, enabled);
}

void FlutterWindowController::RunEventLoop() {
  if (window_) {
    FlutterEmbedderRunWindowLoop(window_);
  }
}

}  // namespace flutter_desktop_embedding

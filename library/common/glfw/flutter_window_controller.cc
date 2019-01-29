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

#include "library/include/flutter_desktop_embedding/glfw/flutter_window_controller.h"

#include <iostream>

namespace flutter_desktop_embedding {

FlutterWindowController::FlutterWindowController(std::string &icu_data_path)
    : icu_data_path_(icu_data_path) {
  init_succeeded_ = FlutterInit();
}

FlutterWindowController::~FlutterWindowController() {
  if (init_succeeded_) {
    FlutterTerminate();
  }
}

bool FlutterWindowController::CreateWindow(
    size_t width, size_t height, const std::string &assets_path,
    const std::vector<std::string> &arguments) {
  if (!init_succeeded_) {
    std::cerr << "Could not create window; FlutterInit failed." << std::endl;
    return false;
  }

  if (window_) {
    std::cerr << "Only one Flutter window can exist at a time." << std::endl;
    return false;
  }

  window_ = CreateFlutterWindow(width, height, assets_path, icu_data_path_,
                                arguments);
  if (!window_) {
    std::cerr << "Failed to create window." << std::endl;
    return false;
  }
  return true;
}

PluginRegistrar *FlutterWindowController::GetRegistrarForPlugin(
    const std::string &plugin_name) {
  if (!window_) {
    return nullptr;
  }
  return flutter_desktop_embedding::GetRegistrarForPlugin(window_, plugin_name);
}

void FlutterWindowController::RunEventLoop() {
  if (window_) {
    FlutterWindowLoop(window_);
  }
}

}  // namespace flutter_desktop_embedding

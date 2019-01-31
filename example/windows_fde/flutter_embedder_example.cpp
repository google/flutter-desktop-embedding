// Copyright 2018 Google LLC
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

#include <iostream>
#include <string>
#include <vector>

#include "flutter_desktop_embedding/glfw/flutter_window_controller.h"

int main(int argc, char **argv) {
  // TODO: Make paths relative to the executable so it can be run from anywhere.
  std::string assets_path = "..\\build\\flutter_assets";
  std::string icu_data_path =
      "..\\..\\library\\windows\\dependencies\\engine\\icudtl.dat";

  // Arguments for the Flutter Engine.
  std::vector<std::string> arguments;
#ifndef _DEBUG
  arguments.push_back("--disable-dart-asserts");
#endif
  flutter_desktop_embedding::FlutterWindowController flutter_controller(
      icu_data_path);

  // Start the engine.
  if (!flutter_controller.CreateWindow(640, 480, assets_path, arguments)) {
    return EXIT_FAILURE;
  }

  // Run until the window is closed.
  flutter_controller.RunEventLoop();
  return EXIT_SUCCESS;
}

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
#include <cstdlib>
#include <iostream>
#include <memory>
#include <vector>

#include <color_panel/color_panel_plugin.h>
#include <file_chooser/file_chooser_plugin.h>
#include <flutter_desktop_embedding/embedder.h>

int main(int argc, char **argv) {
  std::string flutter_example_root = "../example_flutter";
  if (!glfwInit()) {
    std::cout << "Couldn't init GLFW";
  }
  // Arguments for the Flutter Engine.
  std::vector<std::string> arguments;
  // First argument is argv[0] since the engine is expecting real command line
  // args.
  arguments.push_back(argv[0]);
#ifdef NDEBUG
  arguments.push_back("--dart-non-checked-mode");
#endif
  // Start the engine.
  auto window = flutter_desktop_embedding::CreateFlutterWindowInSnapshotMode(
      640, 480, flutter_example_root + "/build/flutter_assets",
      "example/icudtl.dat", arguments);
  if (window == nullptr) {
    glfwTerminate();
    return EXIT_FAILURE;
  }

  // Register any native plugins.
  AddPlugin(window, std::make_unique<plugins_color_panel::ColorPanelPlugin>());
  AddPlugin(window,
            std::make_unique<plugins_file_chooser::FileChooserPlugin>());

  flutter_desktop_embedding::FlutterWindowLoop(window);
  glfwTerminate();
  return EXIT_SUCCESS;
}

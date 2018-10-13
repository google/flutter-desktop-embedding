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
#include <linux/limits.h>
#include <unistd.h>

#include <cstdlib>
#include <iostream>
#include <memory>
#include <vector>

#include <color_panel/color_panel_plugin.h>
#include <file_chooser/file_chooser_plugin.h>
#include <flutter_desktop_embedding/embedder.h>
#include <menubar/menubar_plugin.h>

namespace {

// Returns the path of the directory containing this executable, or an empty
// string if the directory cannot be found.
std::string GetExecutableDirectory() {
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
  return executable_path.substr(0, last_separator_position);
}

}  // namespace

int main(int argc, char **argv) {
  if (!glfwInit()) {
    std::cerr << "Couldn't init GLFW" << std::endl;
  }

  // Resources are located relative to the executable.
  std::string base_directory = GetExecutableDirectory();
  if (base_directory.empty()) {
    base_directory = ".";
  }
  std::string data_directory = base_directory + "/data";
  std::string assets_path = data_directory + "/flutter_assets";
  std::string icu_data_path = data_directory + "/icudtl.dat";

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
      640, 480, assets_path, icu_data_path, arguments);
  if (window == nullptr) {
    glfwTerminate();
    return EXIT_FAILURE;
  }

  // Register any native plugins.
  AddPlugin(window, std::make_unique<plugins_menubar::MenubarPlugin>());
  AddPlugin(window, std::make_unique<plugins_color_panel::ColorPanelPlugin>());
  AddPlugin(window,
            std::make_unique<plugins_file_chooser::FileChooserPlugin>());

  flutter_desktop_embedding::FlutterWindowLoop(window);
  glfwTerminate();
  return EXIT_SUCCESS;
}

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

// For plugin-compatible event handling (e.g., modal windows).
#include <X11/Xlib.h>
#include <color_panel_plugin.h>
#include <example_plugin.h>
#include <file_chooser_plugin.h>
#include <flutter/flutter_window_controller.h>
#include <gtk/gtk.h>
#include <menubar_plugin.h>
#include <url_launcher_fde_plugin.h>
#include <window_size_plugin.h>

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
#ifdef NDEBUG
  arguments.push_back("--disable-dart-asserts");
#endif

  flutter::FlutterWindowController flutter_controller(icu_data_path);
  flutter::WindowProperties window_properties = {};
  window_properties.title = "Testbed";
  window_properties.width = 800;
  window_properties.height = 600;

  // Start the engine.
  if (!flutter_controller.CreateWindow(window_properties, assets_path,
                                       arguments)) {
    return EXIT_FAILURE;
  }

  // Register any native plugins.
  ColorPanelRegisterWithRegistrar(
      flutter_controller.GetRegistrarForPlugin("ColorPanel"));
  ExamplePluginRegisterWithRegistrar(
      flutter_controller.GetRegistrarForPlugin("ExamplePlugin"));
  FileChooserRegisterWithRegistrar(
      flutter_controller.GetRegistrarForPlugin("FileChooser"));
  MenubarRegisterWithRegistrar(
      flutter_controller.GetRegistrarForPlugin("Menubar"));
  UrlLauncherRegisterWithRegistrar(
      flutter_controller.GetRegistrarForPlugin("UrlLauncher"));
  WindowSizeRegisterWithRegistrar(
      flutter_controller.GetRegistrarForPlugin("WindowSize"));

  // Set up for GTK event handling, needed by the GTK-based plugins.
  gtk_init(0, nullptr);
  XInitThreads();

  // Run until the window is closed, processing GTK events in parallel for
  // plugin handling.
  while (flutter_controller.RunEventLoopWithTimeout(
      std::chrono::milliseconds(10))) {
    if (gtk_events_pending()) {
      gtk_main_iteration();
    }
  }
  return EXIT_SUCCESS;
}

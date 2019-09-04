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

#include <example_plugin.h>
#include <flutter/flutter_view_controller.h>
#include <url_launcher_fde.h>
#include <windows.h>

#include <codecvt>
#include <iostream>
#include <string>
#include <vector>

#include "win32_window.h"

namespace {

// Returns the path of the directory containing this executable, or an empty
// string if the directory cannot be found.
std::string GetExecutableDirectory() {
  wchar_t buffer[MAX_PATH];
  if (GetModuleFileName(nullptr, buffer, MAX_PATH) == 0) {
    std::cerr << "Couldn't locate executable" << std::endl;
    return "";
  }
  std::wstring_convert<std::codecvt_utf8<wchar_t>> wide_to_utf8;
  std::string executable_path = wide_to_utf8.to_bytes(buffer);
  size_t last_separator_position = executable_path.find_last_of('\\');
  if (last_separator_position == std::string::npos) {
    std::cerr << "Unabled to find parent directory of " << executable_path
              << std::endl;
    return "";
  }
  return executable_path.substr(0, last_separator_position);
}

}  // namespace

int APIENTRY wWinMain(HINSTANCE instance, HINSTANCE prev, wchar_t *command_line,
                      int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    ::AllocConsole();
  }

  // Resources are located relative to the executable.
  std::string base_directory = GetExecutableDirectory();
  if (base_directory.empty()) {
    base_directory = ".";
  }
  std::string data_directory = base_directory + "\\data";
  std::string assets_path = data_directory + "\\flutter_assets";
  std::string icu_data_path = data_directory + "\\icudtl.dat";

  // Arguments for the Flutter Engine.
  std::vector<std::string> arguments;
#ifndef _DEBUG
  arguments.push_back("--disable-dart-asserts");
#endif
  // Height and width for content and top-level window.
  const int width = 800;
  const int height = 600;

  flutter::FlutterViewController flutter_controller(
      icu_data_path, width, height, assets_path, arguments);

  // Register any native plugins.
  ExamplePluginRegisterWithRegistrar(
      flutter_controller.GetRegistrarForPlugin("ExamplePlugin"));
  UrlLauncherRegisterWithRegistrar(
      flutter_controller.GetRegistrarForPlugin("UrlLauncherPlugin"));

  // Create a top-level win32 window to host the Flutter view.
  Win32Window window;
  if (!window.CreateAndShow(L"Testbed", 10, 10, width, height)) {
    return EXIT_FAILURE;
  }

  window.SetChildContent(flutter_controller.GetNativeWindow());

  // Run messageloop with a hook for flutter_view to do work.
  window.RunMessageLoop(
      [&flutter_controller]() { flutter_controller.ProcessMessages(); });

  return EXIT_SUCCESS;
}

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

#include "flutter/flutter_window_controller.h"

// Include windows.h last, to minimize potential conflicts. The CreateWindow
// macro needs to be undefined because it prevents calling
// FlutterWindowController's method.
#include <windows.h>
#undef CreateWindow

#include <fcntl.h>
#include <io.h>
#include <shellapi.h>
#include <userenv.h>
#include <psapi.h>

#include <ios>
#include <limits>
#include <iostream>
#pragma warning(disable: 4996)

namespace {

// Returns the path of the directory containing this executable, or an empty
// string if the directory cannot be found.
std::string GetExecutableDirectory() {
  char buffer[MAX_PATH];
  if (GetModuleFileName(nullptr, buffer, MAX_PATH) == 0) {
    std::cerr << "Couldn't locate executable" << std::endl;
    return "";
  }
  std::string executable_path(buffer);
  size_t last_separator_position = executable_path.find_last_of('\\');
  if (last_separator_position == std::string::npos) {
    std::cerr << "Unabled to find parent directory of " << executable_path
              << std::endl;
    return "";
  }
  return executable_path.substr(0, last_separator_position);
}

void RouteStdioToConsole(bool create_console_if_not_found) {
  // Don't change anything if stdout or stderr already point to a
  // valid stream.
  //
  // If we are running under Buildbot or under Cygwin's default
  // terminal (mintty), stderr and stderr will be pipe handles.  In
  // that case, we don't want to open CONOUT$, because its output
  // likely does not go anywhere.
  //
  // We don't use GetStdHandle() to check stdout/stderr here because
  // it can return dangling IDs of handles that were never inherited
  // by this process.  These IDs could have been reused by the time
  // this function is called.  The CRT checks the validity of
  // stdout/stderr on startup (before the handle IDs can be reused).
  // _fileno(stdout) will return -2 (_NO_CONSOLE_FILENO) if stdout was
  // invalid.
  if (_fileno(stdout) >= 0 || _fileno(stderr) >= 0) {
    // _fileno was broken for SUBSYSTEM:WINDOWS from VS2010 to VS2012/2013.
    // http://crbug.com/358267. Confirm that the underlying HANDLE is valid
    // before aborting.

    intptr_t stdout_handle = _get_osfhandle(_fileno(stdout));
    intptr_t stderr_handle = _get_osfhandle(_fileno(stderr));
    if (stdout_handle >= 0 || stderr_handle >= 0)
      return;
  }

  if (!AttachConsole(ATTACH_PARENT_PROCESS)) {
    unsigned int result = GetLastError();
    // Was probably already attached.
    if (result == ERROR_ACCESS_DENIED)
      return;
    // Don't bother creating a new console for each child process if the
    // parent process is invalid (eg: crashed).
    if (result == ERROR_GEN_FAILURE)
      return;
    if (create_console_if_not_found) {
      // Make a new console if attaching to parent fails with any other error.
      // It should be ERROR_INVALID_HANDLE at this point, which means the
      // browser was likely not started from a console.
      AllocConsole();
    }
    else {
      return;
    }
  }

  // Arbitrary byte count to use when buffering output lines.  More
  // means potential waste, less means more risk of interleaved
  // log-lines in output.
  enum { kOutputBufferSize = 64 * 1024 };

  if (freopen("CONOUT$", "w", stdout)) {
    setvbuf(stdout, nullptr, _IOLBF, kOutputBufferSize);
    // Overwrite FD 1 for the benefit of any code that uses this FD
    // directly.  This is safe because the CRT allocates FDs 0, 1 and
    // 2 at startup even if they don't have valid underlying Windows
    // handles.  This means we won't be overwriting an FD created by
    // _open() after startup.
    _dup2(_fileno(stdout), 1);
  }
  if (freopen("CONOUT$", "w", stderr)) {
    setvbuf(stderr, nullptr, _IOLBF, kOutputBufferSize);
    _dup2(_fileno(stderr), 2);
  }

  // Fix all cout, wcout, cin, wcin, cerr, wcerr, clog and wclog.
  std::ios::sync_with_stdio();
}

}  // namespace


int APIENTRY wWinMain(HINSTANCE instance, HINSTANCE prev, wchar_t *, int) {

  // 1. if parent or current process has console, attach it.
  // 2. if --force-console exist && parent or current process have not conole, 
  // create and attach it.
  RouteStdioToConsole(
    lpCmdLine
    && wcsstr(lpCmdLine, L"--force-console") != nullptr ? true : false );

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

  flutter::FlutterWindowController flutter_controller(icu_data_path);
  flutter::WindowProperties window_properties = {};
  window_properties.title = "Flutter Desktop Example";
  window_properties.width = 800;
  window_properties.height = 600;

  // Start the engine.
  if (!flutter_controller.CreateWindow(window_properties, assets_path,
                                       arguments)) {
    return EXIT_FAILURE;
  }

  // Run until the window is closed.
  flutter_controller.RunEventLoop();
  return EXIT_SUCCESS;
}

#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <chrono>
#include <iostream>
#include <vector>

#include "flutter/generated_plugin_registrant.h"
#include "run_loop.h"
#include "win32_window.h"
#include "window_configuration.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    ::AllocConsole();
  }

  flutter::DartProject project(L"data");
#ifndef _DEBUG
  project.SetEngineSwitches({"--disable-dart-asserts"});
#endif

  // Top-level window frame.
  Win32Window::Point origin(kFlutterWindowOriginX, kFlutterWindowOriginY);
  Win32Window::Size size(kFlutterWindowWidth, kFlutterWindowHeight);

  flutter::FlutterViewController flutter_controller(size.width, size.height,
                                                    project);
  RegisterPlugins(&flutter_controller);

  // Create a top-level win32 window to host the Flutter view.
  Win32Window window;
  if (!window.CreateAndShow(kFlutterWindowTitle, origin, size)) {
    return EXIT_FAILURE;
  }

  // Parent and resize Flutter view into top-level window.
  window.SetChildContent(flutter_controller.view()->GetNativeWindow());
  window.SetQuitOnClose(true);

  RunLoop run_loop;
  run_loop.RegisterFlutterInstance(&flutter_controller);
  run_loop.Run();
  return EXIT_SUCCESS;
}

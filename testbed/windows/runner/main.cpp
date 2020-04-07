#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <vector>

#include "flutter_window.h"
#include "run_loop.h"
#include "window_configuration.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance,
                      _In_opt_ HINSTANCE prev,
                      _In_ wchar_t* command_line,
                      _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    ::AllocConsole();
  }

  RunLoop run_loop;

  flutter::DartProject project(L"data");
#ifndef _DEBUG
  project.SetEngineSwitches({"--disable-dart-asserts"});
#endif

  FlutterWindow window(&run_loop, project);
  Win32Window::Point origin(kFlutterWindowOriginX, kFlutterWindowOriginY);
  Win32Window::Size size(kFlutterWindowWidth, kFlutterWindowHeight);
  if (!window.CreateAndShow(kFlutterWindowTitle, origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  run_loop.Run();

  return EXIT_SUCCESS;
}

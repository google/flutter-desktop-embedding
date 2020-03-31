#ifndef FLUTTER_WINDOW_H_
#define FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>

#include "run_loop.h"
#include "win32_window.h"

#include <memory>

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow driven by the |run_loop|, hosting a
  // Flutter view running |project|.
  explicit FlutterWindow(RunLoop* run_loop,
                         const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  void OnCreate() override;
  void OnDestroy() override;

 private:
  // The run loop driving events for this window.
  RunLoop* run_loop_;

  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
};

#endif  // FLUTTER_WINDOW_H_

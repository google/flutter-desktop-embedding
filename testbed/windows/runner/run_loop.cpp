#include "run_loop.h"

#include <windows.h>

#include <algorithm>

RunLoop::RunLoop() {}

RunLoop::~RunLoop() {}

void RunLoop::Run() {
  MSG msg;
  while (GetMessage(&msg, nullptr, 0, 0)) {
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }
}

void RunLoop::RegisterFlutterInstance(
    flutter::FlutterEngine* flutter_instance) {
  flutter_instances_.insert(flutter_instance);
}

void RunLoop::UnregisterFlutterInstance(
    flutter::FlutterEngine* flutter_instance) {
  flutter_instances_.erase(flutter_instance);
}

RunLoop::TimePoint RunLoop::ProcessFlutterMessages() {
  TimePoint next_event_time = TimePoint::max();
  for (auto instance : flutter_instances_) {
    std::chrono::nanoseconds wait_duration = instance->ProcessMessages();
    if (wait_duration != std::chrono::nanoseconds::max()) {
      next_event_time =
          std::min(next_event_time, TimePoint::clock::now() + wait_duration);
    }
  }
  return next_event_time;
}

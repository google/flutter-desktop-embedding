// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "win32_window.h"
#include "shellscalingapi.h"

// the Windows DPI system is based on this
// constant for machines running at 100% scaling.
constexpr int base_dpi = 96;

// Scale helper to convert logical scaler values to physical using passed in
// scale factor
int Scale(int source, double scale_factor) {
  return static_cast<int>(static_cast<double>(source * scale_factor));
}

Win32Window::Win32Window() {}

Win32Window::~Win32Window() { Destroy(); }

bool Win32Window::CreateAndShow(const char *title, const unsigned int x,
                                const unsigned int y, const unsigned int width,
                                const unsigned int height) {
  Destroy();

  WNDCLASS window_class = ResgisterWindowClass(title);

  // New windows are created on the default monitor.  Window sizes are specified
  // to the OS in physical pixels, hence to ensure a consistent size to will
  // treat the width height passed in to this function as logical pixels and
  // scale to appropriate for the default monitor.
  HMONITOR defaut_mon = MonitorFromWindow(nullptr, MONITOR_DEFAULTTOPRIMARY);
  UINT dpi_x = 0, dpi_y = 0;
  GetDpiForMonitor(defaut_mon, MDT_EFFECTIVE_DPI, &dpi_x, &dpi_y);

  double scaleFactor = static_cast<double>(dpi_x) / base_dpi;

  auto window = CreateWindow(
      window_class.lpszClassName, title, WS_OVERLAPPEDWINDOW | WS_VISIBLE,
      Scale(x, scaleFactor), Scale(y, scaleFactor), Scale(width, scaleFactor),
      Scale(height, scaleFactor), nullptr, nullptr, window_class.hInstance,
      this);
  if (window == nullptr) {
    return false;
  }
  return true;
}

WNDCLASS Win32Window::ResgisterWindowClass(const char *title) {
  window_class_name_ = title;

  WNDCLASS window_class{};
  window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
  window_class.lpszClassName = "CLASSNAME";
  window_class.style = CS_HREDRAW | CS_VREDRAW;
  window_class.cbClsExtra = 0;
  window_class.cbWndExtra = 0;
  window_class.hInstance = GetModuleHandle(nullptr);
  window_class.hIcon = nullptr;
  window_class.hbrBackground = 0;
  window_class.lpszMenuName = nullptr;
  window_class.lpfnWndProc = WndProc;
  RegisterClass(&window_class);
  return window_class;
}

LRESULT CALLBACK Win32Window::WndProc(HWND const window, UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto cs = reinterpret_cast<CREATESTRUCT *>(lparam);
    SetWindowLongPtr(window, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(cs->lpCreateParams));

    auto that = static_cast<Win32Window *>(cs->lpCreateParams);

    that->window_handle_ = window;
  } else if (Win32Window *that = GetThisFromHandle(window)) {
    return that->MessageHandler(window, message, wparam, lparam);
  }

  return DefWindowProc(window, message, wparam, lparam);
}

LRESULT
Win32Window::MessageHandler(HWND hwnd, UINT const message, WPARAM const wparam,
                            LPARAM const lparam) noexcept {
  int xPos = 0, yPos = 0;
  UINT width = 0, height = 0;
  auto window =
      reinterpret_cast<Win32Window *>(GetWindowLongPtr(hwnd, GWLP_USERDATA));

  if (window != nullptr) {
    switch (message) {
      case WM_DESTROY:
        messageloop_running_ = false;
        return 0;
        break;

      case WM_SIZE:
        RECT rect;
        GetClientRect(hwnd, &rect);
        if (child_content_ != nullptr) {
          // Size and position the child window.
          MoveWindow(child_content_, (rect.left), rect.top,
                     rect.right - rect.left, rect.bottom - rect.top, TRUE);
        }
        return 0;
        break;

      case WM_ACTIVATE:
        if (child_content_ != nullptr) {
          SetFocus(child_content_);
        }
        return 0;
        break;
    }
    return DefWindowProc(hwnd, message, wparam, lparam);
  }

  return DefWindowProc(window_handle_, message, wparam, lparam);
}

void Win32Window::Destroy() {
  if (window_handle_) {
    DestroyWindow(window_handle_);
    window_handle_ = nullptr;
  }

  UnregisterClass("CLASSNAME", nullptr);
}

Win32Window *Win32Window::GetThisFromHandle(HWND const window) noexcept {
  return reinterpret_cast<Win32Window *>(
      GetWindowLongPtr(window, GWLP_USERDATA));
}

void Win32Window::SetChildContent(HWND content) {
  child_content_ = content;
  auto res = SetParent(content, window_handle_);
  RECT rcClient;
  GetClientRect(window_handle_, &rcClient);

  MoveWindow(content, rcClient.left, rcClient.top,
             rcClient.right - rcClient.left, rcClient.bottom - rcClient.top,
             true);

  SetFocus(child_content_);
}

void Win32Window::RunMessageLoop(std::function<void()> callback) {
  // Run until the window is closed.
  MSG message;
  while (GetMessage(&message, nullptr, 0, 0) &&
         messageloop_running_) {  //&& messageloop_running_) {
    TranslateMessage(&message);
    DispatchMessage(&message);

    // Allow flutter view to process it's messages
    if (callback != nullptr) {
      callback();
    }
  }
}
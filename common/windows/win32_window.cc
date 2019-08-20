// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "win32_window.h"

Win32Window::Win32Window() {
  // Assume Windows 10 1703 or greater for DPI handling.  When running on a
  // older release of Windows where this context doesn't exist, DPI calls will
  // fail and Flutter rendering will be impacted until this is fixed.
  // To handle downlevel correctly, dpi_helper must use the most recent DPI
  // context available should be used: Windows 1703: Per-Monitor V2, 8.1:
  // Per-Monitor V1, Windows 7: System See
  // https://docs.microsoft.com/en-us/windows/win32/hidpi/high-dpi-desktop-application-development-on-windows
  // for more information.

  // TODO the calling applicaiton should participate in setting the DPI.
  // Currently dpi_helper is asserting per-monitor V2.  There are two problems
  // with this: 1) it is advised that the awareness mode is set using manifest,
  // not programatically.  2) The calling executable should be responsible for
  // setting an appropriate scaling mode, not a library.  This will be
  // particularly important once there is a means of hosting Flutter content in
  // an existing app.

  // BOOL result = dpi_helper_->SetProcessDpiAwarenessContext(
  //    DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

  // if (result != TRUE) {
  //  OutputDebugString(L"Failed to set PMV2");
  //}
}
Win32Window::~Win32Window() { Destroy(); }

bool Win32Window::CreateAndShow(const char *title, const unsigned int x,
                                const unsigned int y, const unsigned int width,
                                const unsigned int height) {
  Destroy();

  WNDCLASS window_class = ResgisterWindowClass(title);

  auto window = CreateWindow(
      window_class.lpszClassName, title, WS_OVERLAPPEDWINDOW | WS_VISIBLE, x, y,
      width, height, nullptr, nullptr, window_class.hInstance, this);
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

    //// Since the application is running in Per-monitor V2 mode, turn on
    //// automatic titlebar scaling
    // BOOL result = that->dpi_helper_->EnableNonClientDpiScaling(window);
    // if (result != TRUE) {
    //  OutputDebugString(L"Failed to enable non-client area autoscaling");
    //}
    // that->current_dpi_ = that->dpi_helper_->GetDpiForWindow(window);
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
      case WM_DPICHANGED:
        return HandleDpiChange(window_handle_, wparam, lparam);
        break;

      case WM_DESTROY:
        /*window->OnClose();*/
        return 0;
        break;

      case WM_SIZE:
        RECT rcClient;
        GetClientRect(hwnd, &rcClient);
        auto result = EnumChildWindows(hwnd, Win32Window::EnumChildProc,
                                       (LPARAM)&rcClient);
        return 0;
        break;
    }
    return DefWindowProc(hwnd, message, wparam, lparam);
  }

  return DefWindowProc(window_handle_, message, wparam, lparam);
}

BOOL CALLBACK Win32Window::EnumChildProc(HWND child_window, LPARAM lParam) {
  LPRECT parent_rect;
  int i, idChild;

  // Retrieve the child-window identifier. Use it to set the
  // position of the child window.
  idChild = GetWindowLong(child_window, GWL_ID);

  // Size and position the child window.
  parent_rect = (LPRECT)lParam;
  MoveWindow(child_window, (parent_rect->left), parent_rect->top,
             parent_rect->right - parent_rect->left,
             parent_rect->bottom - parent_rect->top, TRUE);

  return TRUE;
}

void Win32Window::Destroy() {
  if (window_handle_) {
    DestroyWindow(window_handle_);
    window_handle_ = nullptr;
  }

  UnregisterClass("CLASSNAME", nullptr);
}

// DPI Change handler. on WM_DPICHANGE resize the window
LRESULT
Win32Window::HandleDpiChange(HWND hwnd, WPARAM wparam, LPARAM lparam) {
  if (hwnd != nullptr) {
    auto window =
        reinterpret_cast<Win32Window *>(GetWindowLongPtr(hwnd, GWLP_USERDATA));

    UINT uDpi = HIWORD(wparam);
    current_dpi_ = uDpi;
    // window->OnDpiScale(uDpi);

    // Resize the window
    auto lprcNewScale = reinterpret_cast<RECT *>(lparam);
    LONG newWidth = lprcNewScale->right - lprcNewScale->left;
    LONG newHeight = lprcNewScale->bottom - lprcNewScale->top;

    SetWindowPos(hwnd, nullptr, lprcNewScale->left, lprcNewScale->top, newWidth,
                 newHeight, SWP_NOZORDER | SWP_NOACTIVATE);
  }
  return 0;
}

Win32Window *Win32Window::GetThisFromHandle(HWND const window) noexcept {
  return reinterpret_cast<Win32Window *>(
      GetWindowLongPtr(window, GWLP_USERDATA));
}

void Win32Window::SetChildContent(HWND content) {
  auto res = SetParent(content, window_handle_);
  RECT rcClient;
  GetClientRect(window_handle_, &rcClient);

  MoveWindow(content, rcClient.left, rcClient.top,
             rcClient.right - rcClient.left, rcClient.bottom - rcClient.top,
             true);
}
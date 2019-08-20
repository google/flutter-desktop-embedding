// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef WIN32_WINDOW_H_
#define WIN32_WINDOW_H_

#include <Windows.h>
#include <Windowsx.h>

#include <memory>
#include <string>

// A class abstraction for a high DPI aware Win32 Window.  Intended to be
// inherited from by classes that wish to specialize with custom
// rendering and input handling
class Win32Window {
 public:
  Win32Window();
  ~Win32Window();

  // Creates and shows a win32 window with |title| and position and size using |x|,
  // |y|, |width| and |height|
  bool CreateAndShow(const char *title, const unsigned int x, const unsigned int y,
                  const unsigned int width, const unsigned int height);

  // Release OS resources asociated with window.
  void Destroy();

  void SetChildContent(HWND content);

 protected:

  // Registers a window class with default style attributes, cursor and
  // icon.
  WNDCLASS ResgisterWindowClass(const char *title);

  // OS callback called by message pump.  Handles the WM_NCCREATE message which
  // is passed when the non-client area is being created and enables automatic
  // non-client DPI scaling so that the non-client area automatically
  // responsponds to changes in DPI.  All other messages are handled by
  // MessageHandler.
  static LRESULT CALLBACK WndProc(HWND const window, UINT const message,
                                  WPARAM const wparam,
                                  LPARAM const lparam) noexcept;

  // TODO
  static BOOL CALLBACK EnumChildProc(HWND child_window, LPARAM lParam);

  // Processes and route salient window messages for mouse handling,
  // size change and DPI.  Delegates handling of these to member overloads that
  // inheriting classes can handle.
  LRESULT
  MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                 LPARAM const lparam) noexcept;

  // When WM_DPICHANGE resizes the window to the new suggested
  // size and notifies inheriting class.
  LRESULT
  HandleDpiChange(HWND hWnd, WPARAM wParam, LPARAM lParam);

  //// Called when the DPI changes either when a
  //// user drags the window between monitors of differing DPI or when the user
  //// manually changes the scale factor.
  // virtual void OnDpiScale(UINT dpi) = 0;

  UINT GetCurrentDPI();

 private:
  //// Stores new width and height and calls |OnResize| to notify inheritors
  // void HandleResize(UINT width, UINT height);

  // Retrieves a class instance pointer for |window|
  static Win32Window *GetThisFromHandle(HWND const window) noexcept;
  int current_dpi_ = 0;

  // window handle for top level window.
  HWND window_handle_ = nullptr;

  // window handle for hosted content.
  HWND child_content_ = nullptr;

  // Member variable to hold the window title.
  const char* window_class_name_;

  //// Member variable referencing an instance of dpi_helper used to abstract
  /// some / aspects of win32 High DPI handling across different OS versions.
  // std::unique_ptr<Win32DpiHelper> dpi_helper_ =
  //    std::make_unique<Win32DpiHelper>();
};

#endif  // WIN32_WINDOW_H_
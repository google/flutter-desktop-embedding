// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef WIN32_WINDOW_H_
#define WIN32_WINDOW_H_

#include <Windows.h>
#include <Windowsx.h>

#include <functional>
#include <memory>
#include <string>

// A class abstraction for a high DPI-aware Win32 Window.  Intended to be
// inherited from by classes that wish to specialize with custom
// rendering and input handling
class Win32Window {
 public:
  Win32Window();
  ~Win32Window();

  // Creates and shows a win32 window with |title| and position and size using
  // |x|, |y|, |width| and |height|. New windows are created on the default
  // monitor.  Window sizes are specified to the OS in physical pixels, hence to
  // ensure a consistent size to will treat the width height passed in to this
  // function as logical pixels and scale to appropriate for the default
  // monitor. Returns false if window couldn't be created otherwise true.
  bool CreateAndShow(const char *title, const unsigned int x,
                     const unsigned int y, const unsigned int width,
                     const unsigned int height);

  // Release OS resources asociated with window.
  void Destroy();

  // Inserts |content| into the window tree.
  void SetChildContent(HWND content);

  // Process window messages until the user closes the Window.  |callback| will
  // be called on each loop iteration.
  void RunMessageLoop(std::function<void()> callback);

  // Returns the backing Window handle to enable clients to set icon and other
  // window properties.
  HWND GetHandle();

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

  // Processes and route salient window messages for mouse handling,
  // size change and DPI.  Delegates handling of these to member overloads that
  // inheriting classes can handle.
  LRESULT
  MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                 LPARAM const lparam) noexcept;

  //// Called when the DPI changes either when a
  //// user drags the window between monitors of differing DPI or when the user
  //// manually changes the scale factor.
  // virtual void OnDpiScale(UINT dpi) = 0;
  UINT GetCurrentDPI();

 private:
  // should message loop keep running
  bool messageloop_running_ = true;

  // Retrieves a class instance pointer for |window|
  static Win32Window *GetThisFromHandle(HWND const window) noexcept;
  int current_dpi_ = 0;

  // window handle for top level window.
  HWND window_handle_ = nullptr;

  // window handle for hosted content.
  HWND child_content_ = nullptr;

  // Member variable to hold the window title.
  const char *window_class_name_;

  //// Member variable referencing an instance of dpi_helper used to abstract
  /// some / aspects of win32 High DPI handling across different OS versions.
  // std::unique_ptr<Win32DpiHelper> dpi_helper_ =
  //    std::make_unique<Win32DpiHelper>();
};

#endif  // WIN32_WINDOW_H_
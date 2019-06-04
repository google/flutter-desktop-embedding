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
#include "plugins/window_size/linux/window_size_plugin.h"

#include <flutter/flutter_window.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_glfw.h>
#include <flutter/standard_method_codec.h>
#include <gtk/gtk.h>

#include <iostream>
#include <memory>
#include <vector>

namespace plugins_window_size {

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

// See window_size_channel.dart for documentation.
const char kChannelName[] = "flutter/windowsize";
const char kGetScreenListMethod[] = "getScreenList";
const char kGetWindowInfoMethod[] = "getWindowInfo";
const char kSetWindowFrameMethod[] = "setWindowFrame";
const char kFrameKey[] = "frame";
const char kVisibleFrameKey[] = "visibleFrame";
const char kScaleFactorKey[] = "scaleFactor";
const char kScreenKey[] = "screen";

// Returns the screen object that contains monitors.
GdkScreen *GetScreen() {
  GdkDisplay *display = gdk_display_get_default();
  if (!display) {
    return nullptr;
  }
  GdkScreen *screen = gdk_display_get_default_screen(display);
  return screen;
}

// Returns the serializable form of |frame| expected by the platform channel.
EncodableValue GetPlatformChannelRepresentationForFrame(
    const GdkRectangle &frame) {
  return EncodableValue(EncodableList{
      EncodableValue(static_cast<double>(frame.x)),
      EncodableValue(static_cast<double>(frame.y)),
      EncodableValue(static_cast<double>(frame.width)),
      EncodableValue(static_cast<double>(frame.height)),
  });
}

// Extracts information from monitor |monitor_index| of |screen| and returns the
// serializable form expected by the platform channel.
// TODO: Switch to GdkMonitor once GTK-3.22 is sufficiently available.
EncodableValue GetPlatformChannelRepresentationForMonitor(GdkScreen *screen,
                                                          gint monitor_index) {
  if (!screen || monitor_index == -1) {
    return EncodableValue();
  }

  GdkRectangle frame = {};
  gdk_screen_get_monitor_geometry(screen, monitor_index, &frame);
  GdkRectangle visible_frame = {};
  gdk_screen_get_monitor_workarea(screen, monitor_index, &visible_frame);
  double scale_factor =
      gdk_screen_get_monitor_scale_factor(screen, monitor_index);
  return EncodableValue(EncodableMap{
      {EncodableValue(kFrameKey),
       GetPlatformChannelRepresentationForFrame(frame)},
      {EncodableValue(kVisibleFrameKey),
       GetPlatformChannelRepresentationForFrame(visible_frame)},
      {EncodableValue(kScaleFactorKey), EncodableValue(scale_factor)},
  });
}

// Returns the monitor treated as containing a window with the given frame,
// if any.
//
// The heuristic used is:
// - If a monitor contains the frame's origin, return that.
// - If not, but there is at least one monitor, return the first one.
// - Otherwise, return -1.
//
// TODO: Switch to returning GdkMonitor once GTK-3.22 is sufficiently available.
gint GetMonitorIndexForWindowFrame(const GdkRectangle &frame) {
  // Treat the window as being on whichever monitor contains its origin. If
  // none do, use the first monitor (if there is one).
  GdkScreen *screen = GetScreen();
  if (!screen) {
    return -1;
  }
  int monitor_count = gdk_screen_get_n_monitors(screen);
  for (int i = 0; i < monitor_count; ++i) {
    GdkRectangle monitor_frame = {};
    gdk_screen_get_monitor_geometry(screen, i, &monitor_frame);
    if ((frame.x >= monitor_frame.x &&
         frame.x <= monitor_frame.x + monitor_frame.width) &&
        (frame.y >= monitor_frame.y &&
         frame.y <= monitor_frame.y + monitor_frame.width)) {
      return i;
    }
  }
  if (monitor_count > 0) {
    return 0;
  }
  return -1;
}

// Extracts information from |window| and returns the serializable form expected
// by the platform channel.
EncodableValue GetPlatformChannelRepresentationForWindow(
    flutter::FlutterWindow *window) {
  flutter::WindowFrame frame = window->GetFrame();
  GdkRectangle gdk_frame = {};
  gdk_frame.x = frame.left;
  gdk_frame.y = frame.top;
  gdk_frame.width = frame.width;
  gdk_frame.height = frame.height;

  return EncodableValue(EncodableMap{
      {EncodableValue(kFrameKey),
       GetPlatformChannelRepresentationForFrame(gdk_frame)},
      {EncodableValue(kScreenKey),
       GetPlatformChannelRepresentationForMonitor(
           GetScreen(), GetMonitorIndexForWindowFrame(gdk_frame))},
      {EncodableValue(kScaleFactorKey),
       EncodableValue(window->GetScaleFactor())},
  });
}

}  // namespace

class WindowSizePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarGlfw *registrar);

  virtual ~WindowSizePlugin();

 private:
  // Creates a plugin that communicates on the given channel.
  WindowSizePlugin(
      std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel,
      flutter::FlutterWindow *window);

  // Called when a method is called on |channel_|;
  void HandleMethodCall(
      const flutter::MethodCall<EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<EncodableValue>> result);

  // The MethodChannel used for communication with the Flutter engine.
  std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel_;

  // The Flutter window.
  flutter::FlutterWindow *window_;
};

// static
void WindowSizePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarGlfw *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      registrar->messenger(), kChannelName,
      &flutter::StandardMethodCodec::GetInstance());
  auto *channel_pointer = channel.get();

  // Uses new instead of make_unique due to private constructor.
  std::unique_ptr<WindowSizePlugin> plugin(
      new WindowSizePlugin(std::move(channel), registrar->window()));

  channel_pointer->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

WindowSizePlugin::WindowSizePlugin(
    std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel,
    flutter::FlutterWindow *window)
    : channel_(std::move(channel)), window_(window) {}

WindowSizePlugin::~WindowSizePlugin() {}

void WindowSizePlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  if (method_call.method_name().compare(kGetScreenListMethod) == 0) {
    EncodableValue screens(EncodableValue::Type::kList);
    GdkScreen *screen = GetScreen();
    if (!screen) {
      result->Error("Unable to get screen");
      return;
    }
    int monitor_count = gdk_screen_get_n_monitors(screen);
    for (int i = 0; i < monitor_count; ++i) {
      screens.ListValue().push_back(
          GetPlatformChannelRepresentationForMonitor(screen, i));
    }
    result->Success(&screens);
  } else if (method_call.method_name().compare(kGetWindowInfoMethod) == 0) {
    EncodableValue window_info =
        GetPlatformChannelRepresentationForWindow(window_);
    result->Success(&window_info);
  } else if (method_call.method_name().compare(kSetWindowFrameMethod) == 0) {
    if (!method_call.arguments() || !method_call.arguments()->IsList() ||
        method_call.arguments()->ListValue().size() != 4) {
      result->Error("Bad arguments", "Expected 4-element list");
      return;
    }
    // Frame validity (e.g., non-zero size) is assumed to be checked on the Dart
    // side of the call.
    const auto &frame_list = method_call.arguments()->ListValue();
    flutter::WindowFrame frame = {};
    frame.left = static_cast<int>(frame_list[0].DoubleValue());
    frame.top = static_cast<int>(frame_list[1].DoubleValue());
    frame.width = static_cast<int>(frame_list[2].DoubleValue());
    frame.height = static_cast<int>(frame_list[3].DoubleValue());
    window_->SetFrame(frame);
    result->Success();
  } else {
    result->NotImplemented();
  }
}

}  // namespace plugins_window_size

void WindowSizeRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  // The plugin registrar owns the plugin, registered callbacks, etc., so must
  // remain valid for the life of the application.
  static auto *plugin_registrar = new flutter::PluginRegistrarGlfw(registrar);
  plugins_window_size::WindowSizePlugin::RegisterWithRegistrar(
      plugin_registrar);
}

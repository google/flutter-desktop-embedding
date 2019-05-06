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
#include "plugins/window_size/linux/include/window_size/window_size_plugin.h"

#include <gtk/gtk.h>
#include <iostream>
#include <memory>
#include <vector>

#include <flutter/flutter_window.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_glfw.h>
#include <flutter/standard_method_codec.h>

#include "plugins/window_size/common/channel_constants.h"

namespace plugins_window_size {

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

// Returns the serialiable form of |frame| expected by the platform channel.
EncodableValue GetPlatformChannelRepresentationForFrame(
    const GdkRectangle &frame) {
  return EncodableValue(EncodableList{
      EncodableValue(static_cast<double>(frame.x)),
      EncodableValue(static_cast<double>(frame.y)),
      EncodableValue(static_cast<double>(frame.width)),
      EncodableValue(static_cast<double>(frame.height)),
  });
}

// Extracts information from |monitor| and returns the serialiable form expected
// by the platform channel.
EncodableValue GetPlatformChannelRepresentationForMonitor(GdkMonitor *monitor) {
  if (!monitor) {
    return EncodableValue();
  }

  GdkRectangle frame = {};
  gdk_monitor_get_geometry(monitor, &frame);
  GdkRectangle visible_frame = {};
  gdk_monitor_get_workarea(monitor, &visible_frame);
  double scale_factor = gdk_monitor_get_scale_factor(monitor);
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
// - Otherwise, return null.
GdkMonitor *GetMonitorForWindowFrame(const GdkRectangle &frame) {
  // Treat the window as being on whichever monitor contains its origin. If
  // none do, use the first monitor (if there is one).
  EncodableValue screen;
  GdkDisplay *display = gdk_display_get_default();
  if (display) {
    int monitor_count = gdk_display_get_n_monitors(display);
    for (int i = 0; i < monitor_count; ++i) {
      GdkMonitor *monitor = gdk_display_get_monitor(display, i);
      GdkRectangle monitor_frame = {};
      gdk_monitor_get_geometry(monitor, &monitor_frame);
      if ((frame.x >= monitor_frame.x &&
           frame.x <= monitor_frame.x + monitor_frame.width) &&
          (frame.y >= monitor_frame.y &&
           frame.y <= monitor_frame.y + monitor_frame.width)) {
        return monitor;
      }
    }
  }
  return nullptr;
}

// Extracts information from |window| and returns the serialiable form expected
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
      {EncodableValue(kScreenKey), GetPlatformChannelRepresentationForMonitor(
                                       GetMonitorForWindowFrame(gdk_frame))},
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
  registrar->EnableInputBlockingForChannel(kChannelName);

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
    GdkDisplay *display = gdk_display_get_default();
    if (!display) {
      result->Error("Unable to get display");
      return;
    }
    int monitor_count = gdk_display_get_n_monitors(display);
    for (int i = 0; i < monitor_count; ++i) {
      GdkMonitor *monitor = gdk_display_get_monitor(display, i);
      screens.ListValue().push_back(
          GetPlatformChannelRepresentationForMonitor(monitor));
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
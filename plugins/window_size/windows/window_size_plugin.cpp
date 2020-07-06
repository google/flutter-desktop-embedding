// Copyright 2019 Google LLC
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
#include "include/window_size/window_size_plugin.h"

// windows.h must be imported before VersionHelpers.h or it will break
// compilation.
#include <windows.h>

#include <VersionHelpers.h>
#include <flutter/flutter_view.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter_windows.h>

#include <codecvt>
#include <memory>
#include <sstream>

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

// See window_size_channel.dart for documentation.
const char kChannelName[] = "flutter/windowsize";
const char kGetScreenListMethod[] = "getScreenList";
const char kGetWindowInfoMethod[] = "getWindowInfo";
const char kSetWindowFrameMethod[] = "setWindowFrame";
const char kSetWindowTitleMethod[] = "setWindowTitle";
const char kFrameKey[] = "frame";
const char kVisibleFrameKey[] = "visibleFrame";
const char kScaleFactorKey[] = "scaleFactor";
const char kScreenKey[] = "screen";

const double kBaseDpi = 96.0;

// Returns the serializable form of |frame| expected by the platform channel.
EncodableValue GetPlatformChannelRepresentationForRect(const RECT &rect) {
  return EncodableValue(EncodableList{
      EncodableValue(static_cast<double>(rect.left)),
      EncodableValue(static_cast<double>(rect.top)),
      EncodableValue(static_cast<double>(rect.right) -
                     static_cast<double>(rect.left)),
      EncodableValue(static_cast<double>(rect.bottom) -
                     static_cast<double>(rect.top)),
  });
}

// Extracts information from monitor |monitor| and returns the
// serializable form expected by the platform channel.
EncodableValue GetPlatformChannelRepresentationForMonitor(HMONITOR monitor) {
  if (!monitor) {
    return EncodableValue();
  }

  MONITORINFO info;
  info.cbSize = sizeof(MONITORINFO);
  GetMonitorInfo(monitor, &info);
  UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
  double scale_factor = dpi / kBaseDpi;
  return EncodableValue(EncodableMap{
      {EncodableValue(kFrameKey),
       GetPlatformChannelRepresentationForRect(info.rcMonitor)},
      {EncodableValue(kVisibleFrameKey),
       GetPlatformChannelRepresentationForRect(info.rcWork)},
      {EncodableValue(kScaleFactorKey), EncodableValue(scale_factor)},
  });
}

BOOL CALLBACK MonitorRepresentationEnumProc(HMONITOR monitor, HDC hdc,
                                            LPRECT clip, LPARAM list_ref) {
  EncodableValue *monitors = reinterpret_cast<EncodableValue *>(list_ref);
  monitors->ListValue().push_back(
      GetPlatformChannelRepresentationForMonitor(monitor));
  return TRUE;
}

// Extracts information from |window| and returns the serializable form expected
// by the platform channel.
EncodableValue GetPlatformChannelRepresentationForWindow(HWND window) {
  if (!window) {
    return EncodableValue();
  }
  RECT frame;
  GetWindowRect(window, &frame);
  HMONITOR window_monitor = MonitorFromWindow(window, MONITOR_DEFAULTTOPRIMARY);
  double scale_factor = FlutterDesktopGetDpiForHWND(window) / kBaseDpi;

  return EncodableValue(EncodableMap{
      {EncodableValue(kFrameKey),
       GetPlatformChannelRepresentationForRect(frame)},
      {EncodableValue(kScreenKey),
       GetPlatformChannelRepresentationForMonitor(window_monitor)},
      {EncodableValue(kScaleFactorKey), EncodableValue(scale_factor)},
  });
}

HWND GetRootWindow(flutter::FlutterView *view) {
  return GetAncestor(view->GetNativeWindow(), GA_ROOT);
}

class WindowSizePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  // Creates a plugin that communicates on the given channel.
  WindowSizePlugin(flutter::PluginRegistrarWindows *registrar);

  virtual ~WindowSizePlugin();

 private:
  // Called when a method is called on the plugin channel;
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // The registrar for this plugin, for accessing the window.
  flutter::PluginRegistrarWindows *registrar_;
};

// static
void WindowSizePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), kChannelName,
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<WindowSizePlugin>(registrar);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

WindowSizePlugin::WindowSizePlugin(flutter::PluginRegistrarWindows *registrar)
    : registrar_(registrar) {}

WindowSizePlugin::~WindowSizePlugin(){};

void WindowSizePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare(kGetScreenListMethod) == 0) {
    EncodableValue screens(EncodableValue::Type::kList);
    EnumDisplayMonitors(nullptr, nullptr, MonitorRepresentationEnumProc,
                        reinterpret_cast<LPARAM>(&screens));
    result->Success(&screens);
  } else if (method_call.method_name().compare(kGetWindowInfoMethod) == 0) {
    EncodableValue window_info = GetPlatformChannelRepresentationForWindow(
        GetRootWindow(registrar_->GetView()));
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
    int x = static_cast<int>(frame_list[0].DoubleValue());
    int y = static_cast<int>(frame_list[1].DoubleValue());
    int width = static_cast<int>(frame_list[2].DoubleValue());
    int height = static_cast<int>(frame_list[3].DoubleValue());
    SetWindowPos(GetRootWindow(registrar_->GetView()), nullptr, x, y, width,
                 height, SWP_NOACTIVATE | SWP_NOOWNERZORDER);
    result->Success();
  } else if (method_call.method_name().compare(kSetWindowTitleMethod) == 0) {
    if (!method_call.arguments() || !method_call.arguments()->IsString()) {
      result->Error("Bad arguments", "Expected string");
      return;
    }
    const auto &title = method_call.arguments()->StringValue();
    std::wstring wstr =
        std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>, wchar_t>{}
            .from_bytes(title);
    SetWindowText(GetRootWindow(registrar_->GetView()), wstr.c_str());
    result->Success();
  } else {
    result->NotImplemented();
  }
}

}  // namespace

void WindowSizePluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  WindowSizePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

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

#include "include/menubar/menubar_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>
#include <sstream>

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

// See flutte/flutter's packages/flutter/lib/src/widgets/platform_menu_bar.dart
// for documentation.
constexpr char kChannelName[] = "flutter/menu";
constexpr char kBadArgumentsError[] = "Bad Arguments";
constexpr char kNoScreenError[] = "No Screen";
constexpr char kGetPlatformVersionMethod[] = "getPlatformVersion";
constexpr char kMenuSetMethod[] = "Menu.setMenus";
constexpr char kMenuItemOpenedMethod[] = "Menu.opened";
constexpr char kMenuItemClosedMethod[] = "Menu.closed";
constexpr char kMenuItemSelectedCallbackMethod[] = "Menu.selectedCallback";
constexpr char kMenuActionPrefix[] = "flutter-menu-";
constexpr char kIdKey[] = "id";
constexpr char kLabelKey[] = "label";
constexpr char kEnabledKey[] = "enabled";
constexpr char kChildrenKey[] = "children";
constexpr char kIsDividerKey[] = "isDivider";
constexpr char kShortcutCharacterKey[] = "shortcutCharacter";
constexpr char kShortcutTriggerKey[] = "shortcutTrigger";
constexpr char kShortcutModifiersKey[] = "shortcutModifiers";

// Key shortcut constants
constexpr int kFlutterShortcutModifierMeta = 1 << 0;
constexpr int kFlutterShortcutModifierShift = 1 << 1;
constexpr int kFlutterShortcutModifierAlt = 1 << 2;
constexpr int kFlutterShortcutModifierControl = 1 << 3;

// Starting point for the generated menu IDs.
const unsigned int kFirstMenuId = 1000;

// Looks for |key| in |map|, returning the associated value if it is present, or
// a nullptr if not.
const EncodableValue *ValueOrNull(const EncodableMap &map, const char *key) {
  auto it = map.find(EncodableValue(key));
  if (it == map.end()) {
    return nullptr;
  }
  return &(it->second);
}

// Converts the given UTF-8 string to UTF-16.
std::wstring Utf16FromUtf8(const std::string &utf8_string) {
  if (utf8_string.empty()) {
    return std::wstring();
  }
  int target_length =
      ::MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8_string.data(),
                            static_cast<int>(utf8_string.length()), nullptr, 0);
  if (target_length == 0) {
    return std::wstring();
  }
  std::wstring utf16_string;
  utf16_string.resize(target_length);
  int converted_length =
      ::MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8_string.data(),
                            static_cast<int>(utf8_string.length()),
                            utf16_string.data(), target_length);
  if (converted_length == 0) {
    return std::wstring();
  }
  return utf16_string;
}
}  // namespace

namespace menubar {

// static
void MenubarPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), kChannelName,
          &flutter::StandardMethodCodec::GetInstance());
  auto *channel_pointer = channel.get();

  auto plugin = std::make_unique<MenubarPlugin>(registrar, std::move(channel));

  channel_pointer->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

MenubarPlugin::MenubarPlugin(
    flutter::PluginRegistrarWindows *registrar,
    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel)
    : registrar_(registrar), channel_(std::move(channel)) {
  window_proc_id_ = registrar_->RegisterTopLevelWindowProcDelegate(
      [this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
        return HandleWindowProc(hwnd, message, wparam, lparam);
      });
}

MenubarPlugin::~MenubarPlugin() {
  registrar_->UnregisterTopLevelWindowProcDelegate(window_proc_id_);
}

void MenubarPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare(kMenuSetMethod) == 0) {
    flutter::FlutterView *view = registrar_->GetView();
    HWND window =
        view ? GetAncestor(view->GetNativeWindow(), GA_ROOT) : nullptr;
    if (!window) {
      result->Error(kMenuConstructionError,
                    "Cannot add a menu to a headless engine.");
      return;
    }
    const auto *menu_list = std::get_if<EncodableList>(method_call.arguments());
    if (!menu_list) {
      result->Error(kBadArgumentsError, "Expected a list of menus.");
      return;
    }
    HMENU menu = ::CreateMenu();
    HMENU previous_menu = ::GetMenu(window);
    std::optional<EncodableValue> optional_error =
        PopulateMenu(menu, *menu_list);
    if (optional_error) {
      result->Error(kMenuConstructionError, "Unable to construct menu",
                    EncodableValue(static_cast<int64_t>(::GetLastError())));
      return;
    }
    if (!::SetMenu(window, menu)) {
      result->Error(kMenuConstructionError, "Unable to set menu",
                    EncodableValue(static_cast<int64_t>(::GetLastError())));
      return;
    }
    if (previous_menu) {
      ::DestroyMenu(previous_menu);
    }
    result->Success();
  } else {
    result->NotImplemented();
  }
}

// static
std::optional<EncodableValue> MenubarPlugin::PopulateMenu(
    HMENU menu, const EncodableList &representation) {
  for (const auto &item : representation) {
    auto optional_error = AddMenuItem(menu, std::get<EncodableMap>(item));
    if (optional_error) {
      return optional_error;
    }
  }
  return std::nullopt;
}

// static
std::optional<EncodableValue> MenubarPlugin::AddMenuItem(
    HMENU menu, const EncodableMap &representation) {
  const auto *is_divider =
      std::get_if<bool>(ValueOrNull(representation, kIsDividerKey));
  if (is_divider && *is_divider) {
    if (!::AppendMenu(menu, MF_SEPARATOR, 0, nullptr)) {
      return EncodableValue(static_cast<int64_t>(::GetLastError()));
    }
  } else {
    const auto *label =
        std::get_if<std::string>(ValueOrNull(representation, kLabelKey));
    std::wstring wide_label(label ? Utf16FromUtf8(*label) : L"");
    UINT flags = MF_STRING;

    const auto *enabled =
        std::get_if<bool>(ValueOrNull(representation, kEnabledKey));
    // Default to enabled if no explicit value is provided.
    flags |= (enabled == nullptr || *enabled) ? MF_ENABLED : MF_GRAYED;

    const auto *children =
        std::get_if<EncodableList>(ValueOrNull(representation, kChildrenKey));
    UINT_PTR item_id;
    if (children) {
      flags |= MF_POPUP;
      HMENU submenu = ::CreatePopupMenu();
      PopulateMenu(submenu, *children);
      item_id = reinterpret_cast<UINT_PTR>(submenu);
    } else {
      const auto *menu_id =
          std::get_if<int32_t>(ValueOrNull(representation, kIdKey));
      item_id = menu_id ? (kFirstMenuId + *menu_id) : 0;
    }
    if (!::AppendMenu(menu, flags, item_id, wide_label.c_str())) {
      return EncodableValue(static_cast<int64_t>(::GetLastError()));
    }
  }
  return std::nullopt;
}

std::optional<LRESULT> MenubarPlugin::HandleWindowProc(HWND hwnd, UINT message,
                                                       WPARAM wparam,
                                                       LPARAM lparam) {
  if (message == WM_COMMAND) {
    DWORD menu_id = LOWORD(wparam);
    if (menu_id >= kFirstMenuId) {
      int32_t flutter_id = menu_id - kFirstMenuId;
      channel_->InvokeMethod(kMenuItemSelectedCallbackMethod,
                             std::make_unique<EncodableValue>(flutter_id));
      return 0;
    }
  }
  return std::nullopt;
}

void MenubarPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  MenubarPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
}  // namespace menubar

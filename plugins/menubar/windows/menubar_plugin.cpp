#include "include/menubar/menubar_plugin.h"

#include <Windows.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

// See menu_channel.dart for documentation.
const char kChannelName[] = "flutter/menubar";
const char kMenuSetMethod[] = "Menubar.SetMenu";
const char kMenuItemSelectedCallbackMethod[] = "Menubar.SelectedCallback";
const char kIdKey[] = "id";
const char kLabelKey[] = "label";
const char kEnabledKey[] = "enabled";
const char kChildrenKey[] = "children";
const char kIsDividerKey[] = "isDivider";

const char kBadArgumentsError[] = "Bad Arguments";
const char kMenuConstructionError[] = "Menu Construction Error";

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

class MenubarPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  MenubarPlugin(
      flutter::PluginRegistrarWindows *registrar,
      std::unique_ptr<flutter::MethodChannel<>> channel);

  virtual ~MenubarPlugin();

 private:
  // Fills |menu| with items constructed from the given method channel
  // representation of a menu.
  //
  // On failure, returns an EncodableValue with error details.
  static std::optional<EncodableValue> PopulateMenu(
      HMENU menu, const EncodableList &representation);

  // Constructs a menu item corresponding to the item in |representation|,
  // including recursively creating children if it has a submenu, and adds it to
  // |menu|.
  //
  // On failure, returns an EncodableValue with error details.
  static std::optional<EncodableValue> AddMenuItem(
      HMENU menu, const EncodableMap &representation);

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<> &method_call,
      std::unique_ptr<flutter::MethodResult<>> result);

  // Called for top-level WindowProc delegation.
  std::optional<LRESULT> HandleWindowProc(HWND hwnd, UINT message,
                                          WPARAM wparam, LPARAM lparam);

  // The registrar for this plugin.
  flutter::PluginRegistrarWindows *registrar_;

  // The cannel to send menu item activations on.
  std::unique_ptr<flutter::MethodChannel<>> channel_;

  // The ID of the registered WindowProc handler.
  int window_proc_id_;
};

// static
void MenubarPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<>>(
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
    std::unique_ptr<flutter::MethodChannel<>> channel)
    : registrar_(registrar), channel_(std::move(channel)) {
  window_proc_id_ = registrar_->RegisterTopLevelWindowProcDelegate(
      [this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
        return HandleWindowProc(hwnd, message, wparam, lparam);
      });
}

MenubarPlugin::~MenubarPlugin() {
  registrar_->UnregisterTopLevelWindowProcDelegate(window_proc_id_);
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

void MenubarPlugin::HandleMethodCall(
    const flutter::MethodCall<> &method_call,
    std::unique_ptr<flutter::MethodResult<>> result) {
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
    if (!window) {
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

}  // namespace

void MenubarPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  MenubarPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

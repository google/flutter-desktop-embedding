#ifndef FLUTTER_PLUGIN_MENUBAR_PLUGIN_H_
#define FLUTTER_PLUGIN_MENUBAR_PLUGIN_H_

#include <flutter/basic_message_channel.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windef.h>

#include <memory>
#include <optional>

namespace menubar {

class MenubarPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  MenubarPlugin(
      flutter::PluginRegistrarWindows *registrar,
      std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel);

  virtual ~MenubarPlugin();

  // Disallow copy and assign.
  MenubarPlugin(const MenubarPlugin &) = delete;
  MenubarPlugin &operator=(const MenubarPlugin &) = delete;

  std::optional<flutter::EncodableValue> SetMenus(
      const flutter::EncodableValue *arguments);

 private:
  struct ShortcutEntry;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  std::optional<LRESULT> HandleWindowProc(UINT message, WPARAM wparam,
                                          LPARAM lparam);
  std::optional<flutter::EncodableValue> PopulateMenu(
      HMENU menu, const flutter::EncodableList &representation);

  void CreateAccelerators();

  std::optional<flutter::EncodableValue> AddMenuItem(
      HMENU menu, const flutter::EncodableMap &representation);

  flutter::PluginRegistrarWindows *registrar_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  uint32_t window_proc_id_;
  HHOOK windows_hook_handle_;
  std::map<int32_t, ShortcutEntry> shortcuts_;
  std::map<int64_t, int64_t> shortcut_trigger_lookup_;
  std::map<std::wstring, int64_t> shortcut_character_lookup_;
};

}  // namespace menubar

#endif  // FLUTTER_PLUGIN_MENUBAR_PLUGIN_H_

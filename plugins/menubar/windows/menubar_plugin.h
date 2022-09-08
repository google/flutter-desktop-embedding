#ifndef FLUTTER_PLUGIN_MENUBAR_PLUGIN_H_
#define FLUTTER_PLUGIN_MENUBAR_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace menubar {

class MenubarPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  MenubarPlugin(
    flutter::PluginRegistrarWindows *registrar,
    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel);

  virtual ~MenubarPlugin();

  // Disallow copy and assign.
  MenubarPlugin(const MenubarPlugin&) = delete;
  MenubarPlugin& operator=(const MenubarPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

    flutter::PluginRegistrarWindows *registrar;
    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel;
};

}  // namespace menubar

#endif  // FLUTTER_PLUGIN_MENUBAR_PLUGIN_H_

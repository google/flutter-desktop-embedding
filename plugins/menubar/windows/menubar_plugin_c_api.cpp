#include "include/menubar/menubar_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "menubar_plugin.h"

void MenubarPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  menubar::MenubarPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

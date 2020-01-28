//
//  Generated file. Do not edit.
//

#include "generated_plugin_registrant.h"

#include <color_panel_plugin.h>
#include <file_chooser_plugin.h>
#include <menubar_plugin.h>
#include <sample_plugin.h>
#include <url_launcher_plugin.h>
#include <window_size_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  ColorPanelPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ColorPanelPlugin"));
  FileChooserPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FileChooserPlugin"));
  MenubarPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("MenubarPlugin"));
  SamplePluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("SamplePlugin"));
  UrlLauncherPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherPlugin"));
  WindowSizePluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("WindowSizePlugin"));
}

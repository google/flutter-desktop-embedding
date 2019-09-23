//
//  Generated file. Do not edit.
//

#include "generated_plugin_registrant.h"

#include <example_plugin.h>
#include <url_launcher_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  ExamplePluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ExamplePlugin"));
  UrlLauncherPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherPlugin"));
}

// Once the Flutter tooling switches to use GTK, this will be generated
// automatically. For now, plugins must be added here manually.

#include "gtk_plugin_registrant.h"

#include <color_panel/color_panel_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) color_panel_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "ColorPanelPlugin");
  color_panel_plugin_register_with_registrar(color_panel_registrar);
}

// Once the Flutter tooling switches to use GTK, this will be generated
// automatically. For now, plugins must be added here manually.

#include "gtk_plugin_registrant.h"

#include <color_panel/color_panel_plugin.h>
#include <file_chooser/file_chooser_plugin.h>
#include <window_size/window_size_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) color_panel_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "ColorPanelPlugin");
  color_panel_plugin_register_with_registrar(color_panel_registrar);
  g_autoptr(FlPluginRegistrar) file_chooser_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry,
                                                  "FileChooserPlugin");
  file_chooser_plugin_register_with_registrar(file_chooser_registrar);
  g_autoptr(FlPluginRegistrar) window_size_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "WindowSizePlugin");
  window_size_plugin_register_with_registrar(window_size_registrar);
}

// Once the Flutter tooling switches to use GTK, this will be generated
// automatically. For now, plugins must be added here manually.

#include "gtk_plugin_registrant.h"

#include <window_size/window_size_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) window_size_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "WindowSizePlugin");
  window_size_plugin_register_with_registrar(window_size_registrar);
}

// Once the Flutter tooling switches to use GTK, this will be generated
// automatically. For now, plugins must be added here manually.

#include "gtk_plugin_registrant.h"

#include <file_chooser/file_chooser_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) file_chooser_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry,
                                                  "FileChooserPlugin");
  file_chooser_plugin_register_with_registrar(file_chooser_registrar);
}

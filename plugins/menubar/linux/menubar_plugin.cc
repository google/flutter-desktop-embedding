// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "include/menubar/menubar_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

// See menu_channel.dart for documentation.
const char kChannelName[] = "flutter/menubar";
const char kBadArgumentsError[] = "Bad Arguments";
const char kNoScreenError[] = "No Screen";
const char kFailureError[] = "Failure";
const char kMenuSetMethod[] = "Menubar.SetMenu";
const char kMenuItemSelectedCallbackMethod[] = "Menubar.SelectedCallback";
const char kIdKey[] = "id";
const char kLabelKey[] = "label";
const char kEnabledKey[] = "enabled";
const char kChildrenKey[] = "children";
const char kIsDividerKey[] = "isDivider";

struct _FlMenubarPlugin {
  GObject parent_instance;

  FlPluginRegistrar* registrar;

  // Connection to Flutter engine.
  FlMethodChannel* channel;

  // Special handle used to indicate a divider.
  GMenuItem* divider_item;

  // Menu being shown to the user.
  GMenu* menu;
};

G_DEFINE_TYPE(FlMenubarPlugin, fl_menubar_plugin, g_object_get_type())

static GMenu* value_to_menu(FlMenubarPlugin* self, FlValue* value,
                            GError** error);

// Convert a value received from Flutter to a GtkMenuItem.
static GMenuItem* value_to_menu_item(FlMenubarPlugin* self, FlValue* value,
                                     GError** error) {
  if (fl_value_get_type(value) != FL_VALUE_TYPE_MAP) {
    g_set_error(error, 0, 0, "Menu item map missing or malformed");
    return nullptr;
  }

  FlValue* is_divider_value = fl_value_lookup_string(value, kIsDividerKey);
  if (is_divider_value != nullptr &&
      fl_value_get_type(is_divider_value) == FL_VALUE_TYPE_BOOL &&
      fl_value_get_bool(is_divider_value)) {
    return G_MENU_ITEM(g_object_ref(self->divider_item));
  }

  g_autoptr(GMenuItem) item = g_menu_item_new(nullptr, nullptr);

  FlValue* id_value = fl_value_lookup_string(value, kIdKey);
  if (id_value != nullptr && fl_value_get_type(id_value) == FL_VALUE_TYPE_INT) {
    g_menu_item_set_action_and_target(item, "app.flutter-menu", "x",
                                      fl_value_get_int(id_value));
  }

  FlValue* enabled_value = fl_value_lookup_string(value, kEnabledKey);
  if (enabled_value != nullptr &&
      fl_value_get_type(enabled_value) == FL_VALUE_TYPE_BOOL &&
      !fl_value_get_bool(enabled_value))
    g_menu_item_set_action_and_target(item, "app.flutter-menu-inactive",
                                      nullptr);

  FlValue* label_value = fl_value_lookup_string(value, kLabelKey);
  if (label_value != nullptr &&
      fl_value_get_type(label_value) == FL_VALUE_TYPE_STRING)
    g_menu_item_set_label(item, fl_value_get_string(label_value));

  FlValue* children = fl_value_lookup_string(value, kChildrenKey);
  if (children != nullptr) {
    g_autoptr(GMenu) sub_menu = value_to_menu(self, children, error);
    if (sub_menu == nullptr) return nullptr;

    g_menu_item_set_submenu(item, G_MENU_MODEL(sub_menu));
  }

  return G_MENU_ITEM(g_object_ref(item));
}

// Convert a value received from Flutter to a GtkMenuItem.
static GMenu* value_to_menu(FlMenubarPlugin* self, FlValue* value,
                            GError** error) {
  if (fl_value_get_type(value) != FL_VALUE_TYPE_LIST) {
    g_set_error(error, 0, 0, "Menu list missing or malformed");
    return nullptr;
  }

  g_autoptr(GMenu) menu = g_menu_new();
  g_autoptr(GMenu) section = nullptr;
  for (size_t i = 0; i < fl_value_get_length(value); i++) {
    g_autoptr(GMenuItem) item =
        value_to_menu_item(self, fl_value_get_list_value(value, i), error);
    if (item == nullptr) return nullptr;

    if (item == self->divider_item) {
      if (section != nullptr)
        g_menu_append_section(menu, nullptr, G_MENU_MODEL(section));
      g_clear_object(&section);
    } else {
      if (section == nullptr) section = g_menu_new();
      g_menu_append_item(section, item);
    }
  }
  if (section != nullptr)
    g_menu_append_section(menu, nullptr, G_MENU_MODEL(section));

  return G_MENU(g_object_ref(menu));
}

// Called when a menu item is activated.
static void menu_activate_cb(FlMenubarPlugin* self, GVariant* parameter) {
  gint64 id = g_variant_get_int64(parameter);

  g_autoptr(FlValue) result = fl_value_new_int(id);
  fl_method_channel_invoke_method(self->channel,
                                  kMenuItemSelectedCallbackMethod, result,
                                  nullptr, nullptr, nullptr);
}

// Sets the menu.
static FlMethodResponse* menu_set(FlMenubarPlugin* self, FlValue* args) {
  g_autoptr(GError) error = nullptr;
  g_autoptr(GMenu) menu = value_to_menu(self, args, &error);
  if (menu == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        kBadArgumentsError, error->message, nullptr));
  }

  FlView* view = fl_plugin_registrar_get_view(self->registrar);
  if (view == nullptr) {
    return FL_METHOD_RESPONSE(
        fl_method_error_response_new(kNoScreenError, nullptr, nullptr));
  }

  GtkApplication* app = gtk_window_get_application(
      GTK_WINDOW(gtk_widget_get_toplevel(GTK_WIDGET(view))));
  if (app == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        kFailureError, "Unable to get application", nullptr));
  }

  // Replace existing menu with this one
  g_menu_remove_all(self->menu);
  g_menu_append_section(self->menu, nullptr, G_MENU_MODEL(menu));

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Called when a method call is received from Flutter.
static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  FlMenubarPlugin* self = FL_MENUBAR_PLUGIN(user_data);

  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(method, kMenuSetMethod) == 0) {
    response = menu_set(self, args);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error))
    g_warning("Failed to send method call response: %s", error->message);
}

static void fl_menubar_plugin_dispose(GObject* object) {
  FlMenubarPlugin* self = FL_MENUBAR_PLUGIN(object);

  g_clear_object(&self->registrar);
  g_clear_object(&self->channel);
  g_clear_object(&self->menu);
  g_clear_object(&self->divider_item);

  G_OBJECT_CLASS(fl_menubar_plugin_parent_class)->dispose(object);
}

static void fl_menubar_plugin_class_init(FlMenubarPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_menubar_plugin_dispose;
}

static void fl_menubar_plugin_init(FlMenubarPlugin* self) {
  self->divider_item = g_menu_item_new(nullptr, nullptr);
}

FlMenubarPlugin* fl_menubar_plugin_new(FlPluginRegistrar* registrar) {
  FlMenubarPlugin* self =
      FL_MENUBAR_PLUGIN(g_object_new(fl_menubar_plugin_get_type(), nullptr));

  self->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            kChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, method_call_cb,
                                            g_object_ref(self), g_object_unref);

  // Add a GAction for the menubar to trigger.
  FlView* view = fl_plugin_registrar_get_view(self->registrar);
  GtkApplication* app = nullptr;
  if (view != nullptr) {
    app = gtk_window_get_application(
        GTK_WINDOW(gtk_widget_get_toplevel(GTK_WIDGET(view))));
  }
  if (app != nullptr) {
    g_autoptr(GSimpleAction) inactive_action =
        g_simple_action_new("flutter-menu-inactive", nullptr);
    g_action_map_add_action(G_ACTION_MAP(app), G_ACTION(inactive_action));
    g_simple_action_set_enabled(inactive_action, FALSE);
    g_autoptr(GSimpleAction) action =
        g_simple_action_new("flutter-menu", G_VARIANT_TYPE_INT64);
    g_simple_action_set_enabled(action, TRUE);
    g_signal_connect_object(action, "activate", G_CALLBACK(menu_activate_cb),
                            self, G_CONNECT_SWAPPED);
    g_action_map_add_action(G_ACTION_MAP(app), G_ACTION(action));

    // Set an empty menubar now, as GTK doesn't detect it being changed later
    // on. https://gitlab.gnome.org/GNOME/gtk/-/issues/2834
    self->menu = g_menu_new();
    gtk_application_set_menubar(app, G_MENU_MODEL(self->menu));
    g_object_notify(G_OBJECT(gtk_settings_get_default()),
                    "gtk-shell-shows-menubar");
  }

  return self;
}

void menubar_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  FlMenubarPlugin* plugin = fl_menubar_plugin_new(registrar);
  g_object_unref(plugin);
}

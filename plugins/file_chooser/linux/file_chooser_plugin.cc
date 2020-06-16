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
#include "include/file_chooser/file_chooser_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

// See channel_controller.dart for documentation.
const char kChannelName[] = "flutter/filechooser";
const char kBadArgumentsError[] = "Bad Arguments";
const char kNoScreenError[] = "No Screen";
const char kShowOpenPanelMethod[] = "FileChooser.Show.Open";
const char kShowSavePanelMethod[] = "FileChooser.Show.Save";
const char kInitialDirectoryKey[] = "initialDirectory";
const char kInitialFileNameKey[] = "initialFileName";
const char kAllowedFileTypesKey[] = "allowedFileTypes";
const char kConfirmButtonTextKey[] = "confirmButtonText";
const char kAllowsMultipleSelectionKey[] = "allowsMultipleSelection";
const char kCanChooseDirectoriesKey[] = "canChooseDirectories";

struct _FlFileChooserPlugin {
  GObject parent_instance;

  FlPluginRegistrar* registrar;

  // Connection to Flutter engine.
  FlMethodChannel* channel;
};

G_DEFINE_TYPE(FlFileChooserPlugin, fl_file_chooser_plugin, G_TYPE_OBJECT)

// Converts a file type received from Flutter into a GTK file filter.
static GtkFileFilter* file_type_to_filter(FlValue* value) {
  if (fl_value_get_type(value) != FL_VALUE_TYPE_LIST ||
      fl_value_get_length(value) != 2 ||
      fl_value_get_type(fl_value_get_list_value(value, 0)) !=
          FL_VALUE_TYPE_STRING ||
      fl_value_get_type(fl_value_get_list_value(value, 1)) !=
          FL_VALUE_TYPE_LIST)
    return nullptr;

  const gchar* name = fl_value_get_string(fl_value_get_list_value(value, 0));

  g_autoptr(GtkFileFilter) filter = gtk_file_filter_new();
  gtk_file_filter_set_name(filter, name);
  FlValue* extensions = fl_value_get_list_value(value, 1);
  for (size_t j = 0; j < fl_value_get_length(extensions); j++) {
    FlValue* v = fl_value_get_list_value(extensions, j);
    if (fl_value_get_type(v) != FL_VALUE_TYPE_STRING) return nullptr;

    g_autofree gchar* pattern = g_strdup_printf("*.%s", fl_value_get_string(v));
    gtk_file_filter_add_pattern(filter, pattern);
  }
  if (fl_value_get_length(extensions) == 0)
    gtk_file_filter_add_pattern(filter, "*");

  return GTK_FILE_FILTER(g_object_ref(filter));
}

// Shows the requested dialog type.
static FlMethodResponse* show_dialog(FlFileChooserPlugin* self,
                                     GtkFileChooserAction action,
                                     const gchar* title,
                                     const gchar* default_confirm_button_text,
                                     FlValue* properties) {
  if (fl_value_get_type(properties) != FL_VALUE_TYPE_MAP) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        kBadArgumentsError, "Argument map missing or malformed", nullptr));
  }

  const gchar* confirm_button_text = default_confirm_button_text;
  FlValue* value = fl_value_lookup_string(properties, kConfirmButtonTextKey);
  if (value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_STRING)
    confirm_button_text = fl_value_get_string(value);

  FlView* view = fl_plugin_registrar_get_view(self->registrar);
  if (view == nullptr) {
    return FL_METHOD_RESPONSE(
        fl_method_error_response_new(kNoScreenError, nullptr, nullptr));
  }

  GtkWindow* window = GTK_WINDOW(gtk_widget_get_toplevel(GTK_WIDGET(view)));
  g_autoptr(GtkFileChooserNative) dialog =
      GTK_FILE_CHOOSER_NATIVE(gtk_file_chooser_native_new(
          title, window, action, confirm_button_text, "_Cancel"));

  value = fl_value_lookup_string(properties, kAllowsMultipleSelectionKey);
  if (value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_BOOL) {
    gtk_file_chooser_set_select_multiple(GTK_FILE_CHOOSER(dialog),
                                         fl_value_get_bool(value));
  }

  value = fl_value_lookup_string(properties, kCanChooseDirectoriesKey);
  if (value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_BOOL &&
      fl_value_get_bool(value)) {
    gtk_file_chooser_set_action(GTK_FILE_CHOOSER(dialog),
                                GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER);
  }

  value = fl_value_lookup_string(properties, kInitialDirectoryKey);
  if (value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_STRING) {
    gtk_file_chooser_set_current_folder(GTK_FILE_CHOOSER(dialog),
                                        fl_value_get_string(value));
  }

  value = fl_value_lookup_string(properties, kInitialFileNameKey);
  if (value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_STRING) {
    gtk_file_chooser_set_current_name(GTK_FILE_CHOOSER(dialog),
                                      fl_value_get_string(value));
  }

  value = fl_value_lookup_string(properties, kAllowedFileTypesKey);
  if (value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_LIST) {
    for (size_t i = 0; i < fl_value_get_length(value); i++) {
      FlValue* file_type = fl_value_get_list_value(value, i);
      g_autoptr(GtkFileFilter) filter = file_type_to_filter(file_type);
      if (filter == nullptr) {
        return FL_METHOD_RESPONSE(fl_method_error_response_new(
            kBadArgumentsError, "Allowed file types malformed", nullptr));
      }
      gtk_file_chooser_add_filter(GTK_FILE_CHOOSER(dialog), filter);
    }
  }

  gint response = gtk_native_dialog_run(GTK_NATIVE_DIALOG(dialog));
  g_autoptr(FlValue) result = nullptr;
  if (response == GTK_RESPONSE_ACCEPT) {
    result = fl_value_new_list();
    g_autoptr(GSList) filenames =
        gtk_file_chooser_get_filenames(GTK_FILE_CHOOSER(dialog));
    for (GSList* link = filenames; link != nullptr; link = link->next) {
      g_autofree gchar* filename = static_cast<gchar*>(link->data);
      fl_value_append_take(result, fl_value_new_string(filename));
    }
  }

  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

// Called when a method call is received from Flutter.
static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  FlFileChooserPlugin* self = FL_FILE_CHOOSER_PLUGIN(user_data);

  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(method, kShowOpenPanelMethod) == 0) {
    response = show_dialog(self, GTK_FILE_CHOOSER_ACTION_OPEN, "Open File",
                           "_Open", args);
  } else if (strcmp(method, kShowSavePanelMethod) == 0) {
    response = show_dialog(self, GTK_FILE_CHOOSER_ACTION_SAVE, "Save File",
                           "_Save", args);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error))
    g_warning("Failed to send method call response: %s", error->message);
}

static void fl_file_chooser_plugin_dispose(GObject* object) {
  FlFileChooserPlugin* self = FL_FILE_CHOOSER_PLUGIN(object);

  g_clear_object(&self->registrar);
  g_clear_object(&self->channel);

  G_OBJECT_CLASS(fl_file_chooser_plugin_parent_class)->dispose(object);
}

static void fl_file_chooser_plugin_class_init(FlFileChooserPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_file_chooser_plugin_dispose;
}

static void fl_file_chooser_plugin_init(FlFileChooserPlugin* self) {}

FlFileChooserPlugin* fl_file_chooser_plugin_new(FlPluginRegistrar* registrar) {
  FlFileChooserPlugin* self = FL_FILE_CHOOSER_PLUGIN(
      g_object_new(fl_file_chooser_plugin_get_type(), nullptr));

  self->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            kChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, method_call_cb,
                                            g_object_ref(self), g_object_unref);

  return self;
}

void file_chooser_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  FlFileChooserPlugin* plugin = fl_file_chooser_plugin_new(registrar);
  g_object_unref(plugin);
}

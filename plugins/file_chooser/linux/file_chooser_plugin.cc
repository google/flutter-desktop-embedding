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
#include "include/file_chooser_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

// See channel_controller.dart for documentation.
const char kChannelName[] = "flutter/filechooser";
const char kShowOpenPanelMethod[] = "FileChooser.Show.Open";
const char kShowSavePanelMethod[] = "FileChooser.Show.Save";
const char kInitialDirectoryKey[] = "initialDirectory";
const char kInitialFileNameKey[] = "initialFileName";
const char kAllowedFileTypesKey[] = "allowedFileTypes";
const char kConfirmButtonTextKey[] = "confirmButtonText";
const char kAllowsMultipleSelectionKey[] = "allowsMultipleSelection";
const char kCanChooseDirectoriesKey[] = "canChooseDirectories";

G_DECLARE_FINAL_TYPE(FlFileChooserPlugin, fl_file_chooser_plugin, FL,
                     FILE_CHOOSER_PLUGIN, FlPlugin)

struct _FlFileChooserPlugin {
  FlPlugin parent_instance;

  FlMethodChannel* channel;
};

G_DEFINE_TYPE(FlFileChooserPlugin, fl_file_chooser_plugin, fl_plugin_get_type())

static void method_call_cb(FlMethodChannel* channel, const gchar* method,
                           FlValue* args,
                           FlMethodChannelResponseHandle* response_handle,
                           gpointer user_data) {
  FlFileChooserPlugin* self = FL_FILE_CHOOSER_PLUGIN(user_data);

  if (strcmp(method, kShowOpenPanelMethod) == 0 ||
      strcmp(method, kShowSavePanelMethod) == 0) {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
      fl_method_channel_respond_error(channel, response_handle, "Bad Arguments",
                                      "Argument map missing or malformed");
      return;
    }

    FlValue* value = fl_value_lookup_string(args, kConfirmButtonTextKey);
    const gchar* ok_button_text =
        fl_value_get_type(value) == FL_VALUE_TYPE_STRING
            ? fl_value_get_string(value)
            : nullptr;

    const gchar* title;
    GtkFileChooserAction action;
    if (strcmp(method, kShowOpenPanelMethod) == 0) {
      title = "Open File";
      action = GTK_FILE_CHOOSER_ACTION_OPEN;
      if (ok_button_text == nullptr) ok_button_text = "_Open";
    } else {
      title = "Save File";
      action = GTK_FILE_CHOOSER_ACTION_SAVE;
      if (ok_button_text == nullptr) ok_button_text = "_Save";
    }
    GtkFileChooserDialog* dialog =
        GTK_FILE_CHOOSER_DIALOG(gtk_file_chooser_dialog_new(
            title, nullptr, GTK_FILE_CHOOSER_ACTION_OPEN, ok_button_text,
            GTK_RESPONSE_ACCEPT, "_Cancel", GTK_RESPONSE_CANCEL, nullptr));

    value = fl_value_lookup_string(
        args, kAllowsMultipleSelectionKey) if (fl_value_get_type(value) ==
                                               FL_VALUE_TYPE_BOOL)
        gtk_file_chooser_set_select_multiple(GTK_FILE_CHOOSER(dialog),
                                             fl_value_get_bool(value));

    value = fl_value_lookup_string(
        args, kCanChooseDirectoriesKey) if (fl_value_get_type(value) ==
                                                FL_VALUE_TYPE_BOOL &&
                                            fl_value_get_bool(value))
        gtk_file_chooser_set_action(GTK_FILE_CHOOSER(dialog),
                                    GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER);

    value = fl_value_lookup_string(args, kInitialDirectoryKey);
    if (fl_value_get_type(value) == FL_VALUE_TYPE_STRING)
      gtk_file_chooser_set_current_folder(GTK_FILE_CHOOSER(dialog),
                                          fl_value_get_string(value));

    value = fl_value_lookup_string(args, kInitialFileNameKey);
    if (fl_value_get_type(value) == FL_VALUE_TYPE_STRING)
      gtk_file_chooser_set_current_name(GTK_FILE_CHOOSER(dialog),
                                        fl_value_get_string(value));

    value = fl_value_lookup_string(args, kAllowedFileTypesKey);
    if (fl_value_get_type(value) == FL_VALUE_TYPE_LIST) {
      for (size_t i = 0; i < fl_value_get_length(value); i++) {
        FlValue* filter_info = fl_value_get_list_value(value, i);

        if (fl_value_get_type(filter_info) != FL_VALUE_TYPE_LIST ||
            fl_value_get_length(filter_info) != 2 ||
            fl_value_get_type(fl_value_get_list_value(filter_info, 0)) !=
                FL_VALUE_TYPE_STRING ||
            fl_value_get_type(fl_value_get_list_value(filter_info, 1)) !=
                FL_VALUE_TYPE_LIST)
          continue;

        g_autoptr(GtkFileFilter) filter = gtk_file_filter_new();
        gtk_file_filter_set_name(
            filter,
            fl_value_get_string(fl_value_get_list_value(filter_info, 0)));
        FlValue* extensions =
            fl_value_get_list_value(fl_value_get_list_value(filter_info, 1));
        for (size_t j = 0; j < fl_value_get_length(extensions); j++) {
          FlValue* v = fl_value_get_list_value(extensions, j);
          if (fl_value_get_type(v) != FL_VALUE_TYPE_STRING) continue;

          g_autofree gchar* pattern =
              g_strdup_printf("*.%s", fl_value_get_string(v));
          gtk_file_filter_add_pattern(filter, pattern);
        }
        if (fl_value_get_length(extensions) == 0)
          gtk_file_filter_add_pattern(filter, "*");

        gtk_file_chooser_add_filter(GTK_FILE_CHOOSER(dialog), filter);
      }
    }

    gtk_dialog_run(GTK_DIALOG(dialog));
    gtk_widget_destroy(GTK_WIDGET(dialog));

    g_autoptr(FlValue) result = fl_value_new_list();
    g_autoptr(GSList) filenames =
        gtk_file_chooser_get_filenames(GTK_FILE_CHOOSER(dialog));
    for (GSList* link = filenames; link != nullptr; link = link->next) {
      g_autofree gchar* filename = link->data;
      fl_value_append_take(result, fl_value_new_string(filename));
    }
    fl_method_channel_respond_success(channel, response_handle, result, nullptr);
  } else
    fl_method_channel_respond_not_implemented(channel, response_handle,
                                              nullptr);
}

// FIXME?  registrar->EnableInputBlockingForChannel(kChannelName);

static void fl_file_chooser_plugin_dispose(GObject* object) {
  FlFileChooserPlugin* self = FL_FILE_CHOOSER_PLUGIN(object);

  g_clear_object(&self->channel);
  destroy_file_chooser_dialog(self);

  G_OBJECT_CLASS(fl_file_chooser_plugin_parent_class)->dispose(object);
}

static void fl_file_chooser_plugin_class_init(FlFileChooserPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_file_chooser_plugin_dispose;
}

static void fl_file_chooser_plugin_init(FlFileChooserPlugin* self) {}

static FlFileChooserPlugin* fl_file_chooser_plugin_new(
    FlPluginRegistrar* registrar) {
  FlFileChooserPlugin* self = FL_FILE_CHOOSER_PLUGIN(
      g_object_new(fl_file_chooser_plugin_get_type(), nullptr));

  self->channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            kChannelName, fl_standard_method_codec_new());
  fl_method_channel_set_method_call_handler(self->channel, method_call_cb,
                                            self);

  return self;
}

void file_chooser_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  g_autoptr(FlFileChooserPlugin) plugin = fl_file_chooser_plugin_new(registrar);
  fl_plugin_registrar_add_plugin(registrar, FL_PLUGIN(plugin));
}

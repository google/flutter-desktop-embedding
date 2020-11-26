// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "include/file_selector_linux/file_selector_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

// From method_channel_file_selector.dart
const char kChannelName[] = "plugins.flutter.io/file_selector";

const char kOpenFileMethod[] = "openFile";
const char kGetSavePathMethod[] = "getSavePath";
const char kGetDirectoryPathMethod[] = "getDirectoryPath";

const char kAcceptedTypeGroupsKey[] = "acceptedTypeGroups";
const char kConfirmButtonTextKey[] = "confirmButtonText";
const char kInitialDirectoryKey[] = "initialDirectory";
const char kMultipleKey[] = "multiple";
const char kSuggestedNameKey[] = "suggestedName";

// From x_type_group.dart
const char kTypeGroupLabelKey[] = "label";
const char kTypeGroupExtensionsKey[] = "extensions";
const char kTypeGroupMimeTypesKey[] = "mimeTypes";

// Errors
const char kBadArgumentsError[] = "Bad Arguments";
const char kNoScreenError[] = "No Screen";

struct _FlFileSelectorPlugin {
  GObject parent_instance;

  FlPluginRegistrar* registrar;

  // Connection to Flutter engine.
  FlMethodChannel* channel;
};

G_DEFINE_TYPE(FlFileSelectorPlugin, fl_file_selector_plugin, G_TYPE_OBJECT)

// Converts a type group received from Flutter into a GTK file filter.
static GtkFileFilter* type_group_to_filter(FlValue* value) {
  if (fl_value_get_type(value) != FL_VALUE_TYPE_MAP) {
    return nullptr;
  }

  g_autoptr(GtkFileFilter) filter = gtk_file_filter_new();

  FlValue* label = fl_value_lookup_string(value, kTypeGroupLabelKey);
  if (label != nullptr && fl_value_get_type(label) == FL_VALUE_TYPE_STRING) {
    gtk_file_filter_set_name(filter, fl_value_get_string(label));
  }

  bool has_filter = false;
  FlValue* extensions = fl_value_lookup_string(value, kTypeGroupExtensionsKey);
  if (extensions != nullptr &&
      fl_value_get_type(extensions) == FL_VALUE_TYPE_LIST) {
    for (size_t i = 0; i < fl_value_get_length(extensions); i++) {
      FlValue* v = fl_value_get_list_value(extensions, i);
      if (fl_value_get_type(v) != FL_VALUE_TYPE_STRING) return nullptr;

      g_autofree gchar* pattern =
          g_strdup_printf("*.%s", fl_value_get_string(v));
      gtk_file_filter_add_pattern(filter, pattern);
      has_filter = true;
    }
  }
  FlValue* mime_types = fl_value_lookup_string(value, kTypeGroupMimeTypesKey);
  if (mime_types != nullptr &&
      fl_value_get_type(mime_types) == FL_VALUE_TYPE_LIST) {
    for (size_t i = 0; i < fl_value_get_length(mime_types); i++) {
      FlValue* v = fl_value_get_list_value(mime_types, i);
      if (fl_value_get_type(v) != FL_VALUE_TYPE_STRING) return nullptr;

      const gchar* pattern = fl_value_get_string(v);
      gtk_file_filter_add_mime_type(filter, pattern);
      has_filter = true;
    }
  }
  if (!has_filter) {
    gtk_file_filter_add_pattern(filter, "*");
  }

  return GTK_FILE_FILTER(g_object_ref(filter));
}

// Shows the requested dialog type.
static FlMethodResponse* show_dialog(FlFileSelectorPlugin* self,
                                     GtkFileChooserAction action,
                                     bool choose_directory, const gchar* title,
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

  value = fl_value_lookup_string(properties, kMultipleKey);
  if (value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_BOOL) {
    gtk_file_chooser_set_select_multiple(GTK_FILE_CHOOSER(dialog),
                                         fl_value_get_bool(value));
  }

  if (choose_directory) {
    gtk_file_chooser_set_action(GTK_FILE_CHOOSER(dialog),
                                GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER);
  }

  value = fl_value_lookup_string(properties, kInitialDirectoryKey);
  if (value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_STRING) {
    gtk_file_chooser_set_current_folder(GTK_FILE_CHOOSER(dialog),
                                        fl_value_get_string(value));
  }

  value = fl_value_lookup_string(properties, kSuggestedNameKey);
  if (value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_STRING) {
    gtk_file_chooser_set_current_name(GTK_FILE_CHOOSER(dialog),
                                      fl_value_get_string(value));
  }

  value = fl_value_lookup_string(properties, kAcceptedTypeGroupsKey);
  if (value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_LIST) {
    for (size_t i = 0; i < fl_value_get_length(value); i++) {
      FlValue* type_group = fl_value_get_list_value(value, i);
      GtkFileFilter* filter = type_group_to_filter(type_group);
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
    if (action == GTK_FILE_CHOOSER_ACTION_OPEN && !choose_directory) {
      result = fl_value_new_list();
      g_autoptr(GSList) filenames =
          gtk_file_chooser_get_filenames(GTK_FILE_CHOOSER(dialog));
      for (GSList* link = filenames; link != nullptr; link = link->next) {
        g_autofree gchar* filename = static_cast<gchar*>(link->data);
        fl_value_append_take(result, fl_value_new_string(filename));
      }
    } else {
      g_autofree gchar* filename =
          gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(dialog));
      result = fl_value_new_string(filename);
    }
  }

  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

// Called when a method call is received from Flutter.
static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  FlFileSelectorPlugin* self = FL_FILE_SELECTOR_PLUGIN(user_data);

  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(method, kOpenFileMethod) == 0) {
    response = show_dialog(self, GTK_FILE_CHOOSER_ACTION_OPEN, false,
                           "Open File", "_Open", args);
  } else if (strcmp(method, kGetDirectoryPathMethod) == 0) {
    response = show_dialog(self, GTK_FILE_CHOOSER_ACTION_OPEN, true,
                           "Choose Directory", "_Open", args);
  } else if (strcmp(method, kGetSavePathMethod) == 0) {
    response = show_dialog(self, GTK_FILE_CHOOSER_ACTION_SAVE, false,
                           "Save File", "_Save", args);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error))
    g_warning("Failed to send method call response: %s", error->message);
}

static void fl_file_selector_plugin_dispose(GObject* object) {
  FlFileSelectorPlugin* self = FL_FILE_SELECTOR_PLUGIN(object);

  g_clear_object(&self->registrar);
  g_clear_object(&self->channel);

  G_OBJECT_CLASS(fl_file_selector_plugin_parent_class)->dispose(object);
}

static void fl_file_selector_plugin_class_init(
    FlFileSelectorPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_file_selector_plugin_dispose;
}

static void fl_file_selector_plugin_init(FlFileSelectorPlugin* self) {}

FlFileSelectorPlugin* fl_file_selector_plugin_new(
    FlPluginRegistrar* registrar) {
  FlFileSelectorPlugin* self = FL_FILE_SELECTOR_PLUGIN(
      g_object_new(fl_file_selector_plugin_get_type(), nullptr));

  self->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            kChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, method_call_cb,
                                            g_object_ref(self), g_object_unref);

  return self;
}

void file_selector_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  FlFileSelectorPlugin* plugin = fl_file_selector_plugin_new(registrar);
  g_object_unref(plugin);
}

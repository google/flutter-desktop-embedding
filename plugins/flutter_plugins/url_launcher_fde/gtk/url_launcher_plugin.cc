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
#include "include/url_launcher/url_launcher_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

// See url_launcher_channel.dart for documentation.
const char kChannelName[] = "plugins.flutter.io/url_launcher";
const char kBadArgumentsError[] = "Bad Arguments";
const char kLaunchError[] = "Launch Error";
const char kCanLaunchMethod[] = "canLaunch";
const char kLaunchMethod[] = "launch";
const char kUrlKey[] = "url";

struct _FlUrlLauncherPlugin {
  GObject parent_instance;

  FlPluginRegistrar* registrar;

  // Connection to Flutter engine.
  FlMethodChannel* channel;
};

G_DEFINE_TYPE(FlUrlLauncherPlugin, fl_url_launcher_plugin, g_object_get_type())

// Gets the URL from the arguments or generates an error.
static gchar* get_url(FlValue* args, GError** error) {
  if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    g_set_error(error, 0, 0, "Argument map missing or malformed");
    return nullptr;
  }
  FlValue* url_value = fl_value_lookup_string(args, kUrlKey);
  if (url_value == nullptr) {
    g_set_error(error, 0, 0, "Missing URL");
    return nullptr;
  }

  return g_strdup(fl_value_get_string(url_value));
}

// Called to check if a URL can be launched.
static FlMethodResponse* can_launch(FlUrlLauncherPlugin* self, FlValue* args) {
  g_autoptr(GError) error = nullptr;
  g_autofree gchar* url = get_url(args, &error);
  if (url == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        kBadArgumentsError, error->message, nullptr));
  }

  gboolean is_launchable = FALSE;
  g_autofree gchar* scheme = g_uri_parse_scheme(url);
  if (scheme == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        kLaunchError, "Unable to determine URL scheme", nullptr));
  }

  g_autoptr(GAppInfo) app_info = g_app_info_get_default_for_uri_scheme(scheme);
  is_launchable = app_info != nullptr;

  g_autoptr(FlValue) result = fl_value_new_bool(is_launchable);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

// Called when a URL should launch.
static FlMethodResponse* launch(FlUrlLauncherPlugin* self, FlValue* args) {
  g_autoptr(GError) error = nullptr;
  g_autofree gchar* url = get_url(args, &error);
  if (url == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        kBadArgumentsError, error->message, nullptr));
  }

  FlView* view = fl_plugin_registrar_get_view(self->registrar);
  gboolean launched;
  if (view != nullptr) {
    GtkWindow* window = GTK_WINDOW(gtk_widget_get_toplevel(GTK_WIDGET(view)));
    launched = gtk_show_uri_on_window(window, url, GDK_CURRENT_TIME, &error);
  } else {
    launched = g_app_info_launch_default_for_uri(url, nullptr, &error);
  }
  if (!launched) {
    g_autofree gchar* message =
        g_strdup_printf("Failed to launch URL: %s", error->message);
    return FL_METHOD_RESPONSE(
        fl_method_error_response_new(kLaunchError, message, nullptr));
  }

  g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

// Called when a method call is received from Flutter.
static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  FlUrlLauncherPlugin* self = FL_URL_LAUNCHER_PLUGIN(user_data);

  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(method, kCanLaunchMethod) == 0)
    response = can_launch(self, args);
  else if (strcmp(method, kLaunchMethod) == 0)
    response = launch(self, args);
  else
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error))
    g_warning("Failed to send method call response: %s", error->message);
}

static void fl_url_launcher_plugin_dispose(GObject* object) {
  FlUrlLauncherPlugin* self = FL_URL_LAUNCHER_PLUGIN(object);

  g_clear_object(&self->registrar);
  g_clear_object(&self->channel);

  G_OBJECT_CLASS(fl_url_launcher_plugin_parent_class)->dispose(object);
}

static void fl_url_launcher_plugin_class_init(FlUrlLauncherPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_url_launcher_plugin_dispose;
}

FlUrlLauncherPlugin* fl_url_launcher_plugin_new(FlPluginRegistrar* registrar) {
  FlUrlLauncherPlugin* self = FL_URL_LAUNCHER_PLUGIN(
      g_object_new(fl_url_launcher_plugin_get_type(), nullptr));

  self->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            kChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, method_call_cb,
                                            g_object_ref(self), g_object_unref);

  return self;
}

static void fl_url_launcher_plugin_init(FlUrlLauncherPlugin* self) {}

void url_launcher_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  FlUrlLauncherPlugin* plugin = fl_url_launcher_plugin_new(registrar);
  g_object_unref(plugin);
}

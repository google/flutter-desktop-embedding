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
#include "include/color_panel/color_panel_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

// See color_panel.dart for documentation.
const char kChannelName[] = "flutter/colorpanel";
const char kShowColorPanelMethod[] = "ColorPanel.Show";
const char kColorPanelShowAlpha[] = "ColorPanel.ShowAlpha";
const char kHideColorPanelMethod[] = "ColorPanel.Hide";
const char kColorSelectedCallbackMethod[] = "ColorPanel.ColorSelectedCallback";
const char kClosedCallbackMethod[] = "ColorPanel.ClosedCallback";
const char kColorComponentAlphaKey[] = "alpha";
const char kColorComponentRedKey[] = "red";
const char kColorComponentGreenKey[] = "green";
const char kColorComponentBlueKey[] = "blue";

static constexpr char kWindowTitle[] = "Flutter Color Picker";

struct _FlColorPanelPlugin {
  GObject parent_instance;

  FlPluginRegistrar* registrar;

  // Connection to Flutter engine.
  FlMethodChannel* channel;

  // Dialog currently being shown.
  GtkColorChooserDialog* color_chooser_dialog;
};

G_DEFINE_TYPE(FlColorPanelPlugin, fl_color_panel_plugin, g_object_get_type())

// Destroys any open color chooser dialog.
static void destroy_color_chooser_dialog(FlColorPanelPlugin* self) {
  if (self->color_chooser_dialog == nullptr) return;

  gtk_widget_destroy(GTK_WIDGET(self->color_chooser_dialog));
  self->color_chooser_dialog = nullptr;
}

// Called when a color chooser dialog responds.
static void color_chooser_response_cb(FlColorPanelPlugin* self,
                                      gint response_id) {
  if (response_id == GTK_RESPONSE_OK) {
    GdkRGBA color;
    gtk_color_chooser_get_rgba(GTK_COLOR_CHOOSER(self->color_chooser_dialog),
                               &color);
    g_autoptr(FlValue) result = fl_value_new_map();
    fl_value_set_string_take(result, kColorComponentAlphaKey,
                             fl_value_new_float(color.alpha));
    fl_value_set_string_take(result, kColorComponentRedKey,
                             fl_value_new_float(color.red));
    fl_value_set_string_take(result, kColorComponentGreenKey,
                             fl_value_new_float(color.green));
    fl_value_set_string_take(result, kColorComponentBlueKey,
                             fl_value_new_float(color.blue));
    fl_method_channel_invoke_method(self->channel, kColorSelectedCallbackMethod,
                                    result, nullptr, nullptr, nullptr);
  }

  fl_method_channel_invoke_method(self->channel, kClosedCallbackMethod, nullptr,
                                  nullptr, nullptr, nullptr);

  destroy_color_chooser_dialog(self);
}

// Shows a color panel.
static FlMethodResponse* show_color_panel(FlColorPanelPlugin* self,
                                          FlValue* args) {
  // There is only one color panel that can be displayed at once.
  // There are no channels to use the color panel, so just return.
  if (self->color_chooser_dialog != nullptr)
    return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));

  FlValue* use_alpha_value = nullptr;
  if (fl_value_get_type(args) == FL_VALUE_TYPE_MAP)
    use_alpha_value = fl_value_lookup_string(args, kColorPanelShowAlpha);
  gboolean use_alpha =
      use_alpha_value != nullptr ? fl_value_get_bool(use_alpha_value) : FALSE;

  self->color_chooser_dialog = GTK_COLOR_CHOOSER_DIALOG(
      gtk_color_chooser_dialog_new(kWindowTitle, nullptr));
  FlView* view = fl_plugin_registrar_get_view(self->registrar);
  GtkWindow* window = GTK_WINDOW(gtk_widget_get_parent(GTK_WIDGET(view)));
  gtk_window_set_transient_for(GTK_WINDOW(self->color_chooser_dialog), window);
  gtk_color_chooser_set_use_alpha(GTK_COLOR_CHOOSER(self->color_chooser_dialog),
                                  use_alpha);
  g_signal_connect_object(self->color_chooser_dialog, "response",
                          G_CALLBACK(color_chooser_response_cb), self,
                          G_CONNECT_SWAPPED);
  gtk_widget_show(GTK_WIDGET(self->color_chooser_dialog));

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Hides the color panel.
static FlMethodResponse* hide_color_panel(FlColorPanelPlugin* self) {
  destroy_color_chooser_dialog(self);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

// Called when a method call is received from Flutter.
static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  FlColorPanelPlugin* self = FL_COLOR_PANEL_PLUGIN(user_data);

  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(method, kShowColorPanelMethod) == 0) {
    response = show_color_panel(self, args);
  } else if (strcmp(method, kHideColorPanelMethod) == 0) {
    response = hide_color_panel(self);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error))
    g_warning("Failed to send method call response: %s", error->message);
}

static void fl_color_panel_plugin_dispose(GObject* object) {
  FlColorPanelPlugin* self = FL_COLOR_PANEL_PLUGIN(object);

  g_clear_object(&self->registrar);
  g_clear_object(&self->channel);
  destroy_color_chooser_dialog(self);

  G_OBJECT_CLASS(fl_color_panel_plugin_parent_class)->dispose(object);
}

static void fl_color_panel_plugin_class_init(FlColorPanelPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_color_panel_plugin_dispose;
}

static void fl_color_panel_plugin_init(FlColorPanelPlugin* self) {}

FlColorPanelPlugin* fl_color_panel_plugin_new(FlPluginRegistrar* registrar) {
  FlColorPanelPlugin* self = FL_COLOR_PANEL_PLUGIN(
      g_object_new(fl_color_panel_plugin_get_type(), nullptr));

  self->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            kChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, method_call_cb,
                                            g_object_ref(self), g_object_unref);

  return self;
}

void color_panel_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  FlColorPanelPlugin* plugin = fl_color_panel_plugin_new(registrar);
  g_object_unref(plugin);
}

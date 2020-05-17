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
#include "include/window_size_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

// See window_size_channel.dart for documentation.
const char kChannelName[] = "flutter/windowsize";
const char kGetScreenListMethod[] = "getScreenList";
const char kGetWindowInfoMethod[] = "getWindowInfo";
const char kSetWindowFrameMethod[] = "setWindowFrame";
const char kSetWindowTitleMethod[] = "setWindowTitle";
const char kFrameKey[] = "frame";
const char kVisibleFrameKey[] = "visibleFrame";
const char kScaleFactorKey[] = "scaleFactor";
const char kScreenKey[] = "screen";

G_DECLARE_FINAL_TYPE(FlWindowSizePlugin, fl_window_size_plugin, FL,
                     WINDOW_SIZE_PLUGIN, FlPlugin)

struct _FlWindowSizePlugin {
  FlPlugin parent_instance;

  FlView *view;
  FlMethodChannel* channel;
};

G_DEFINE_TYPE(FlWindowSizePlugin, fl_window_size_plugin, fl_plugin_get_type())

static void method_call_cb(FlMethodChannel* channel, const gchar* method,
                           FlValue* args,
                           FlMethodChannelResponseHandle* response_handle,
                           gpointer user_data) {
  FlWindowSizePlugin* self = FL_WINDOW_SIZE_PLUGIN(user_data);

  if (strcmp(method, kGetScreenListMethod) == 0) {
    g_autoptr(FlValue) result = fl_value_new_list();
    //FIXME
    fl_method_channel_respond_success(channel, response_handle, result, nullptr);
  } else if (strcmp(method, kGetWindowInfoMethod) == 0) {
    GtkWindow *window = GTK_WINDOW(gtk_widget_get_parent(self->view));
    gint x, y;
    gtk_window_get_position(window, &x, &y);
    gint width, height;
    gtk_window_get_size(window, &width, &height);

    g_autoptr(FlValue) result = fl_value_new_map();
    g_autoptr(FlValue) frame = fl_value_new_list();
    fl_value_append_take(frame, fl_value_new_double(x));
    fl_value_append_take(frame, fl_value_new_double(y));
    fl_value_append_take(frame, fl_value_new_double(width));
    fl_value_append_take(frame, fl_value_new_double(height));
    fl_value_set_string(result, kFrameKey, frame);
    fl_value_set_string_take(result, kScreenKey, ...);
    fl_value_set_string_take(result, kScaleFactorKey, ...);

    fl_method_channel_respond_success(channel, response_handle, result, nullptr);
  } else if (strcmp(method, kSetWindowFrameMethod) == 0) {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_LIST ||
        fl_value_get_length(args) != 4) {
      fl_method_channel_respond_not_error(channel, response_handle, "Bad arguments", "Expected 4-element list", nullptr);
      return;
    }

    GtkWindow *window = GTK_WINDOW(gtk_widget_get_parent(self->view));

    double x = fl_value_get_double(fl_value_get_list_value(args, 0));
    double y = fl_value_get_double(fl_value_get_list_value(args, 1));
    double width = fl_value_get_double(fl_value_get_list_value(args, 2));
    double height = fl_value_get_double(fl_value_get_list_value(args, 3));
    gtk_window_move(window, x, y);
    gtk_window_resize(window, width, height);

    fl_method_channel_respond_success(channel, response_handle, nullptr, nullptr);
  } else if (strcmp(method, kSetWindowTitleMethod) == 0) {
    if (fl_value_get_type(args) != FL_VALUE_TYPE_STRING) {
      fl_method_channel_respond_not_error(channel, response_handle, "Bad arguments", "Expected string", nullptr);
      return;
    }
    gtk_window_set_title(GTK_WINDOW(gtk_widget_get_parent(self->view)), fl_value_get_string(args));

    fl_method_channel_respond_success(channel, response_handle, nullptr, nullptr);
  } else
    fl_method_channel_respond_not_implemented(channel, response_handle,
                                              nullptr);
}

// Returns the screen object that contains monitors.
GdkScreen *GetScreen() {
  GdkDisplay *display = gdk_display_get_default();
  if (!display) {
    return nullptr;
  }
  GdkScreen *screen = gdk_display_get_default_screen(display);
  return screen;
}

// Returns the serializable form of |frame| expected by the platform channel.
EncodableValue GetPlatformChannelRepresentationForFrame(
    const GdkRectangle &frame) {
  return EncodableValue(EncodableList{
      EncodableValue(static_cast<double>(frame.x)),
      EncodableValue(static_cast<double>(frame.y)),
      EncodableValue(static_cast<double>(frame.width)),
      EncodableValue(static_cast<double>(frame.height)),
  });
}

// Extracts information from monitor |monitor_index| of |screen| and returns the
// serializable form expected by the platform channel.
// TODO: Switch to GdkMonitor once GTK-3.22 is sufficiently available.
EncodableValue GetPlatformChannelRepresentationForMonitor(GdkScreen *screen,
                                                          gint monitor_index) {
  if (!screen || monitor_index == -1) {
    return EncodableValue();
  }

  GdkRectangle frame = {};
  gdk_screen_get_monitor_geometry(screen, monitor_index, &frame);
  GdkRectangle visible_frame = {};
  gdk_screen_get_monitor_workarea(screen, monitor_index, &visible_frame);
  double scale_factor =
      gdk_screen_get_monitor_scale_factor(screen, monitor_index);
  return EncodableValue(EncodableMap{
      {EncodableValue(kFrameKey),
       GetPlatformChannelRepresentationForFrame(frame)},
      {EncodableValue(kVisibleFrameKey),
       GetPlatformChannelRepresentationForFrame(visible_frame)},
      {EncodableValue(kScaleFactorKey), EncodableValue(scale_factor)},
  });
}

// Returns the monitor treated as containing a window with the given frame,
// if any.
//
// The heuristic used is:
// - If a monitor contains the frame's origin, return that.
// - If not, but there is at least one monitor, return the first one.
// - Otherwise, return -1.
//
// TODO: Switch to returning GdkMonitor once GTK-3.22 is sufficiently available.
gint GetMonitorIndexForWindowFrame(const GdkRectangle &frame) {
  // Treat the window as being on whichever monitor contains its origin. If
  // none do, use the first monitor (if there is one).
  GdkScreen *screen = GetScreen();
  if (!screen) {
    return -1;
  }
  int monitor_count = gdk_screen_get_n_monitors(screen);
  for (int i = 0; i < monitor_count; ++i) {
    GdkRectangle monitor_frame = {};
    gdk_screen_get_monitor_geometry(screen, i, &monitor_frame);
    if ((frame.x >= monitor_frame.x &&
         frame.x <= monitor_frame.x + monitor_frame.width) &&
        (frame.y >= monitor_frame.y &&
         frame.y <= monitor_frame.y + monitor_frame.width)) {
      return i;
    }
  }
  if (monitor_count > 0) {
    return 0;
  }
  return -1;
}

// Extracts information from |window| and returns the serializable form expected
// by the platform channel.
EncodableValue GetPlatformChannelRepresentationForWindow(
    flutter::FlutterWindow *window) {
  flutter::WindowFrame frame = window->GetFrame();
  GdkRectangle gdk_frame = {};
  gdk_frame.x = frame.left;
  gdk_frame.y = frame.top;
  gdk_frame.width = frame.width;
  gdk_frame.height = frame.height;

  return EncodableValue(EncodableMap{
      {EncodableValue(kFrameKey),
       GetPlatformChannelRepresentationForFrame(gdk_frame)},
      {EncodableValue(kScreenKey),
       GetPlatformChannelRepresentationForMonitor(
           GetScreen(), GetMonitorIndexForWindowFrame(gdk_frame))},
      {EncodableValue(kScaleFactorKey),
       EncodableValue(window->GetScaleFactor())},
  });
}

}  // namespace

class WindowSizePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarGlfw *registrar);

  virtual ~WindowSizePlugin();

 private:
  // Creates a plugin that communicates on the given channel.
  WindowSizePlugin(
      std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel,
      flutter::FlutterWindow *window);

  // Called when a method is called on |channel_|;
  void HandleMethodCall(
      const flutter::MethodCall<EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<EncodableValue>> result);

  // The MethodChannel used for communication with the Flutter engine.
  std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel_;

  // The Flutter window.
  flutter::FlutterWindow *window_;
};

WindowSizePlugin::WindowSizePlugin(
    std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel,
    flutter::FlutterWindow *window)
    : channel_(std::move(channel)), window_(window) {}

WindowSizePlugin::~WindowSizePlugin() {}

void WindowSizePlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  if (method_call.method_name().compare(kGetScreenListMethod) == 0) {
    EncodableValue screens(EncodableValue::Type::kList);
    GdkScreen *screen = GetScreen();
    if (!screen) {
      result->Error("Unable to get screen");
      return;
    }
    int monitor_count = gdk_screen_get_n_monitors(screen);
    for (int i = 0; i < monitor_count; ++i) {
      screens.ListValue().push_back(
          GetPlatformChannelRepresentationForMonitor(screen, i));
    }
    result->Success(&screens);
}

static void fl_window_size_plugin_dispose(GObject* object) {
  FlWindowSizePlugin* self = FL_WINDOW_SIZE_PLUGIN(object);

  g_clear_object(&self->channel);

  G_OBJECT_CLASS(fl_window_size_plugin_parent_class)->dispose(object);
}

static void fl_window_size_plugin_class_init(FlWindowSizePluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_window_size_plugin_dispose;
}

static void fl_window_size_plugin_init(FlWindowSizePlugin* self) {}

static FlWindowSizePlugin* fl_window_size_plugin_new(
    FlPluginRegistrar* registrar) {
  FlWindowSizePlugin* self = FL_WINDOW_SIZE_PLUGIN(
      g_object_new(fl_window_size_plugin_get_type(), nullptr));

  self->view = fl_plugin_registrar_get_view(registrar);
  self->channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            kChannelName, fl_standard_method_codec_new());
  fl_method_channel_set_method_call_handler(self->channel, method_call_cb,
                                            self);

  return self;
}

void window_size_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  g_autoptr(FlWindowSizePlugin) plugin = fl_window_size_plugin_new(registrar);
  fl_plugin_registrar_add_plugin(registrar, FL_PLUGIN(plugin));
}

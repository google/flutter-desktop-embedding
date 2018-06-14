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
#include <color_panel/color_panel_plugin.h>

#include <gtk/gtk.h>
#include <iostream>

#include "../common/channel_constants.h"

static constexpr char kWindowTitle[] = "Flutter Color Picker";

namespace plugins_color_panel {
using flutter_desktop_embedding::MethodCall;
using flutter_desktop_embedding::MethodResult;

// Private implementation class containing the color picker widget.
//
// This is to avoid having the user import extra GTK headers.
class ColorPanelPlugin::ColorPanel {
 public:
  explicit ColorPanel(ColorPanelPlugin *parent) {
    gtk_widget_ = gtk_color_chooser_dialog_new(kWindowTitle, nullptr);
    gtk_widget_show_all(gtk_widget_);
    g_signal_connect(gtk_widget_, "close", G_CALLBACK(CloseCallback), parent);
    g_signal_connect(gtk_widget_, "response", G_CALLBACK(ResponseCallback),
                     parent);
  }

  virtual ~ColorPanel() {
    if (gtk_widget_) {
      gtk_widget_destroy(gtk_widget_);
      gtk_widget_ = nullptr;
    }
  }

  // Converts a color from RGBA to RGB in the form of a JSON object.
  //
  // The format of the message is intended for platform consumption.  The
  // conversion assumes that the background color will be black.
  static Json::Value GdkColorToArgs(const GdkRGBA *color) {
    Json::Value result;
    result[kColorComponentRedKey] = color->red * color->alpha;
    result[kColorComponentGreenKey] = color->green * color->alpha;
    result[kColorComponentBlueKey] = color->blue * color->alpha;
    return result;
  }

  // Handler for when the user closes the color chooser dialog.
  //
  // This is not to be conflated with hitting the cancel button. That action is
  // handled in the ResponseCallback function.
  static void CloseCallback(GtkDialog *dialog, gpointer data) {
    auto plugin = reinterpret_cast<ColorPanelPlugin *>(data);
    plugin->HidePanel(ColorPanelPlugin::CloseRequestSource::kUserAction);
  }

  // Handler for when the user chooses a button on the chooser dialog.
  //
  // This includes the cancel button as well as the select button.
  static void ResponseCallback(GtkWidget *dialog, gint response_id,
                               gpointer data) {
    auto plugin = reinterpret_cast<ColorPanelPlugin *>(data);
    if (response_id == GTK_RESPONSE_OK) {
      GdkRGBA color;
      gtk_color_chooser_get_rgba(GTK_COLOR_CHOOSER(dialog), &color);
      plugin->InvokeMethod(kColorSelectedCallbackMethod,
                           GdkColorToArgs(&color));
    }
    // Need this to close the color handler.
    plugin->HidePanel(CloseRequestSource::kUserAction);
  }

 private:
  GtkWidget *gtk_widget_;
};

ColorPanelPlugin::ColorPanelPlugin()
    : Plugin(kChannelName), color_panel_(nullptr) {}

ColorPanelPlugin::~ColorPanelPlugin() {}

void ColorPanelPlugin::HandleMethodCall(const MethodCall &method_call,
                                        std::unique_ptr<MethodResult> result) {
  if (method_call.method_name().compare(kShowColorPanelMethod) == 0) {
    result->Success();
    // There is only one color panel that can be displayed at once.
    // There are no channels to use the color panel, so just return.
    if (color_panel_) {
      return;
    }
    color_panel_ = std::make_unique<ColorPanelPlugin::ColorPanel>(this);
  } else if (method_call.method_name().compare(kHideColorPanelMethod) == 0) {
    result->Success();
    if (color_panel_ == nullptr) {
      return;
    }
    HidePanel(CloseRequestSource::kPlatformChannel);
  } else {
    result->NotImplemented();
  }
}

void ColorPanelPlugin::HidePanel(CloseRequestSource source) {
  color_panel_.reset();
  if (source == CloseRequestSource::kUserAction) {
    InvokeMethod(kClosedCallbackMethod);
  }
}

}  // namespace plugins_color_panel

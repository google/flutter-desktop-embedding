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
#include <flutter_desktop_embedding/color_picker_plugin.h>

#include <gtk/gtk.h>
#include <iostream>

#include <flutter_desktop_embedding/common/platform_protocol.h>

static constexpr char kChannelName[] = "flutter/colorpanel";
static constexpr char kWindowTitle[] = "Flutter Color Picker";

static constexpr char kShowColorPanelMethod[] = "ColorPanel.Show";
static constexpr char kHideColorPanelMethod[] = "ColorPanel.Hide";
static constexpr char kColorPanelCallback[] = "ColorPanel.Callback";

static constexpr char kColorPanelRedComponentKey[] = "red";
static constexpr char kColorPanelGreenComponentKey[] = "green";
static constexpr char kColorPanelBlueComponentKey[] = "blue";

static const float kColorComponentMaxValue = 255.0;

namespace flutter_desktop_embedding {

// Private implementation class containing the color picker widget.
//
// This is to avoid having the user import extra GTK headers.
class ColorPickerPlugin::ColorPicker {
 public:
  explicit ColorPicker(ColorPickerPlugin *parent) {
    gtk_widget_ = gtk_color_chooser_dialog_new(kWindowTitle, nullptr);
    gtk_widget_show_all(gtk_widget_);
    g_signal_connect(gtk_widget_, "close", G_CALLBACK(CloseCallback), parent);
    g_signal_connect(gtk_widget_, "response", G_CALLBACK(ResponseCallback),
                     parent);
  }

  virtual ~ColorPicker() {
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
    result[kColorPanelRedComponentKey] =
        static_cast<int>((color->red * color->alpha) * kColorComponentMaxValue);
    result[kColorPanelGreenComponentKey] = static_cast<int>(
        (color->green * color->alpha) * kColorComponentMaxValue);
    result[kColorPanelBlueComponentKey] = static_cast<int>(
        (color->blue * color->alpha) * kColorComponentMaxValue);
    return result;
  }

  // Handler for when the user closes the color chooser dialog.
  //
  // This is not to be conflated with hitting the cancel button. That action is
  // handled in the ResponseCallback function.
  static void CloseCallback(GtkDialog *dialog, gpointer data) {
    auto plugin = reinterpret_cast<ColorPickerPlugin *>(data);
    Json::Value message;
    message[kMethodKey] = kHideColorPanelMethod;

    // Need this to close the color handler.
    plugin->HandlePlatformMessage(message);
  }

  // Handler for when the user chooses a button on the chooser dialog.
  //
  // This includes the cancel button as well as the select button.
  static void ResponseCallback(GtkWidget *dialog, gint response_id,
                               gpointer data) {
    auto plugin = reinterpret_cast<ColorPickerPlugin *>(data);
    Json::Value plugin_message;
    plugin_message[kMethodKey] = kHideColorPanelMethod;
    if (response_id == GTK_RESPONSE_OK) {
      GdkRGBA color;
      gtk_color_chooser_get_rgba(GTK_COLOR_CHOOSER(dialog), &color);
      Json::Value callback_message;
      callback_message[kMethodKey] = kColorPanelCallback;
      callback_message[kArgumentsKey] = Json::arrayValue;
      callback_message[kArgumentsKey].append(GdkColorToArgs(&color));
      plugin->SendMessageToFlutterEngine(callback_message);
    }
    // Need this to close the color handler.
    plugin->HandlePlatformMessage(plugin_message);
  }

 private:
  GtkWidget *gtk_widget_;
};

ColorPickerPlugin::ColorPickerPlugin()
    : Plugin(kChannelName), color_picker_(nullptr) {}

ColorPickerPlugin::~ColorPickerPlugin() {}

Json::Value ColorPickerPlugin::HandlePlatformMessage(
    const Json::Value &message) {
  Json::Value result;
  Json::Value method = message[kMethodKey];
  if (method.isNull()) {
    std::cerr << "No color picker method selected" << std::endl;
    return Json::nullValue;
  }

  if (method.compare(kShowColorPanelMethod) == 0) {
    // There is only one color picker that can be displayed at once.
    // There are no channels to use the color picker, so just return.
    if (color_picker_) {
      return Json::nullValue;
    }
    color_picker_ = std::make_unique<ColorPickerPlugin::ColorPicker>(this);
  }
  if (method.compare(kHideColorPanelMethod) == 0) {
    if (color_picker_ == nullptr) {
      return Json::nullValue;
    }
    // Destroys the color picker.
    color_picker_.reset();
  }
  return Json::nullValue;
}

}  // namespace flutter_desktop_embedding

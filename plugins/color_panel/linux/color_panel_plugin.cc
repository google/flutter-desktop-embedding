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
#include "plugins/color_panel/linux/color_panel_plugin.h"

#include <gtk/gtk.h>
#include <iostream>
#include <memory>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>
#include <flutter/standard_method_codec.h>

namespace plugins_color_panel {

namespace {
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
}

static constexpr char kWindowTitle[] = "Flutter Color Picker";

using flutter::EncodableMap;
using flutter::EncodableValue;

class ColorPanelPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrar *registrar);

  virtual ~ColorPanelPlugin();

 protected:
  // The source of a request to hide the panel, either a user action or
  // a programmatic request via the platform channel.
  enum class CloseRequestSource { kUserAction, kPlatformChannel };

  // Hides the color picker panel if it is showing.
  void HidePanel(CloseRequestSource source);

 private:
  // Creates a plugin that communicates on the given channel.
  ColorPanelPlugin(
      std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel);

  // Called when a method is called on |channel_|;
  void HandleMethodCall(
      const flutter::MethodCall<EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<EncodableValue>> result);

  // The MethodChannel used for communication with the Flutter engine.
  std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel_;

  // Private implementation.
  class ColorPanel;
  std::unique_ptr<ColorPanel> color_panel_;
};

// Private implementation class containing the color picker widget.
//
// This is to avoid having the user import extra GTK headers.
class ColorPanelPlugin::ColorPanel {
 public:
  explicit ColorPanel(ColorPanelPlugin *parent,
                      const EncodableValue *method_args) {
    gtk_widget_ = gtk_color_chooser_dialog_new(kWindowTitle, nullptr);
    bool use_alpha = false;
    if (method_args) {
      const auto &arg_map = method_args->MapValue();
      auto it = arg_map.find(EncodableValue(kColorPanelShowAlpha));
      if (it != arg_map.end()) {
        use_alpha = it->second.BoolValue();
      }
    }
    gtk_color_chooser_set_use_alpha(
        reinterpret_cast<GtkColorChooser *>(gtk_widget_), use_alpha);
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

  // Converts a color from ARGB to a encodable object.
  //
  // The format of the message is intended for platform consumption.
  static EncodableValue GdkColorToArgs(const GdkRGBA *color) {
    return EncodableValue(EncodableMap{
        {EncodableValue(kColorComponentAlphaKey), EncodableValue(color->alpha)},
        {EncodableValue(kColorComponentRedKey), EncodableValue(color->red)},
        {EncodableValue(kColorComponentGreenKey), EncodableValue(color->green)},
        {EncodableValue(kColorComponentBlueKey), EncodableValue(color->blue)},
    });
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
      plugin->channel_->InvokeMethod(
          kColorSelectedCallbackMethod,
          std::make_unique<EncodableValue>(GdkColorToArgs(&color)));
    }
    // Need this to close the color handler.
    plugin->HidePanel(CloseRequestSource::kUserAction);
  }

 private:
  GtkWidget *gtk_widget_;
};

// static
void ColorPanelPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrar *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      registrar->messenger(), kChannelName,
      &flutter::StandardMethodCodec::GetInstance());
  auto *channel_pointer = channel.get();

  // Uses new instead of make_unique due to private constructor.
  std::unique_ptr<ColorPanelPlugin> plugin(
      new ColorPanelPlugin(std::move(channel)));

  channel_pointer->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

ColorPanelPlugin::ColorPanelPlugin(
    std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel)
    : channel_(std::move(channel)), color_panel_(nullptr) {}

ColorPanelPlugin::~ColorPanelPlugin() {}

void ColorPanelPlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  if (method_call.method_name().compare(kShowColorPanelMethod) == 0) {
    result->Success();
    // There is only one color panel that can be displayed at once.
    // There are no channels to use the color panel, so just return.
    if (color_panel_) {
      return;
    }
    color_panel_ = std::make_unique<ColorPanelPlugin::ColorPanel>(
        this, method_call.arguments());
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
    channel_->InvokeMethod(kClosedCallbackMethod, nullptr);
  }
}

}  // namespace plugins_color_panel

void ColorPanelRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  // The plugin registrar owns the plugin, registered callbacks, etc., so must
  // remain valid for the life of the application.
  static auto *plugin_registrar = new flutter::PluginRegistrar(registrar);
  plugins_color_panel::ColorPanelPlugin::RegisterWithRegistrar(
      plugin_registrar);
}

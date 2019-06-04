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

#include "plugins/menubar/linux/menubar_plugin.h"

#include <gtk/gtk.h>
#include <memory>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>
#include <flutter/standard_method_codec.h>

static constexpr char kWindowTitle[] = "Flutter Menubar";

namespace plugins_menubar {

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;

// See menu_channel.dart for documentation.
const char kChannelName[] = "flutter/menubar";
const char kMenuSetMethod[] = "Menubar.SetMenu";
const char kMenuItemSelectedCallbackMethod[] = "Menubar.SelectedCallback";
const char kIdKey[] = "id";
const char kLabelKey[] = "label";
const char kEnabledKey[] = "enabled";
const char kChildrenKey[] = "children";
const char kDividerKey[] = "isDivider";

}

class MenubarPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrar *registrar);

  virtual ~MenubarPlugin();

 private:
  // Creates a plugin that communicates on the given channel.
  MenubarPlugin(
      std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel);

  // Called when a method is called on |channel_|;
  void HandleMethodCall(
      const flutter::MethodCall<EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<EncodableValue>> result);

  // The MethodChannel used for communication with the Flutter engine.
  std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel_;

  class Menubar;
  std::unique_ptr<Menubar> menubar_;
};

// static
void MenubarPlugin::RegisterWithRegistrar(flutter::PluginRegistrar *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      registrar->messenger(), kChannelName,
      &flutter::StandardMethodCodec::GetInstance());
  auto *channel_pointer = channel.get();

  // Uses new instead of make_unique due to private constructor.
  std::unique_ptr<MenubarPlugin> plugin(new MenubarPlugin(std::move(channel)));

  channel_pointer->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

MenubarPlugin::MenubarPlugin(
    std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel)
    : channel_(std::move(channel)) {}

MenubarPlugin::~MenubarPlugin() {}

// Class containing the implementation of the Menubar widget. This is currently
// a floating GTK window, separate from the main app. This is not the optimal
// solution.
class MenubarPlugin::Menubar {
 public:
  explicit Menubar(MenubarPlugin *parent) {
    menubar_window_ = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_position(GTK_WINDOW(menubar_window_), GTK_WIN_POS_CENTER);
    gtk_window_set_default_size(GTK_WINDOW(menubar_window_), 300, 50);
    gtk_window_set_title(GTK_WINDOW(menubar_window_), kWindowTitle);

    GtkWidget *vbox = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
    gtk_container_add(GTK_CONTAINER(menubar_window_), vbox);

    menubar_ = gtk_menu_bar_new();
    gtk_box_pack_start(GTK_BOX(vbox), menubar_, FALSE, FALSE, 0);
  }
  virtual ~Menubar() {
    if (menubar_window_) {
      gtk_widget_destroy(menubar_window_);
      gtk_widget_destroy(menubar_);
    }
  }

  // Gets the top level menubar widget.
  GtkWidget *GetRootMenuBar() { return menubar_; }

  // Triggers an action once a menubar item has been selected.
  static void MenuItemSelected(GtkWidget *menuItem, gpointer *data) {
    auto plugin = reinterpret_cast<MenubarPlugin *>(data);

    plugin->channel_->InvokeMethod(kMenuItemSelectedCallbackMethod,
                                   std::make_unique<EncodableValue>(std::stoi(
                                       gtk_widget_get_name(menuItem))));
  }

  // Creates the menu items heirarchy from a given channel representation.
  void SetMenuItems(const EncodableValue &root, flutter::Plugin *plugin,
                    GtkWidget *parentWidget) {
    if (root.IsList()) {
      // This is the base of the menu representation. It's not a menu item
      // itself, so there's no need to create a widget.
      for (const auto &menu : root.ListValue()) {
        SetMenuItems(menu, plugin, parentWidget);
      }
      gtk_widget_show_all(menubar_window_);

      return;
    }

    // Everything else is a map.
    const EncodableMap &menu_info = root.MapValue();
    auto label_it = menu_info.find(EncodableValue(kLabelKey));
    if (label_it != menu_info.end()) {
      std::string label = label_it->second.StringValue();

      auto enabled_it = menu_info.find(EncodableValue(kEnabledKey));
      bool enabled =
          enabled_it == menu_info.end() ? true : enabled_it->second.BoolValue();

      auto children_it = menu_info.find(EncodableValue(kChildrenKey));
      if (children_it != menu_info.end()) {
        // A parent menu item. Creates a widget with its label and then build
        // the children.
        const EncodableValue &children = children_it->second;
        auto menu = gtk_menu_new();
        auto menuItem = gtk_menu_item_new_with_label(label.c_str());

        gtk_widget_set_sensitive(menuItem, enabled);
        gtk_menu_item_set_submenu(GTK_MENU_ITEM(menuItem), menu);
        gtk_menu_shell_append(GTK_MENU_SHELL(parentWidget), menuItem);

        SetMenuItems(children, plugin, menu);
      } else {
        // A leaf menu item. Only these items will have a callback.
        auto menuItem = gtk_menu_item_new_with_label(label.c_str());
        gtk_widget_set_sensitive(menuItem, enabled);

        auto id_it = menu_info.find(EncodableValue(kIdKey));
        if (id_it != menu_info.end()) {
          std::string idString = std::to_string(id_it->second.IntValue());
          gtk_widget_set_name(menuItem, idString.c_str());
        }
        g_signal_connect(G_OBJECT(menuItem), "activate",
                         G_CALLBACK(MenuItemSelected), plugin);
        gtk_menu_shell_append(GTK_MENU_SHELL(parentWidget), menuItem);
      }
    }

    auto divider_it = menu_info.find(EncodableValue(kDividerKey));
    if (divider_it != menu_info.end() && divider_it->second.BoolValue()) {
      auto separator = gtk_separator_menu_item_new();
      gtk_menu_shell_append(GTK_MENU_SHELL(parentWidget), separator);
    }
    gtk_widget_show_all(menubar_window_);
  }

  // Removes all items from the menubar.
  void ClearMenuItems() {
    GList *children, *iter;

    children = gtk_container_get_children(GTK_CONTAINER(menubar_));
    for (iter = children; iter != NULL; iter = g_list_next(iter)) {
      gtk_widget_destroy(GTK_WIDGET(iter->data));
    }
    g_list_free(children);
  }

 protected:
  GtkWidget *menubar_window_;
  GtkWidget *menubar_;
};

void MenubarPlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  if (method_call.method_name().compare(kMenuSetMethod) == 0) {
    if (!method_call.arguments() || method_call.arguments()->IsNull()) {
      result->Error("Bad Arguments", "Null menu bar arguments received");
      return;
    }

    if (menubar_ == nullptr) {
      menubar_ = std::make_unique<MenubarPlugin::Menubar>(this);
    }
    // The menubar will be redrawn after every interaction. Clear items to avoid
    // duplication.
    menubar_->ClearMenuItems();
    menubar_->SetMenuItems(*method_call.arguments(), this,
                           menubar_->GetRootMenuBar());
    result->Success();
  } else {
    result->NotImplemented();
  }
}

}  // namespace plugins_menubar

void MenubarRegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar) {
  // The plugin registrar owns the plugin, registered callbacks, etc., so must
  // remain valid for the life of the application.
  static auto *plugin_registrar = new flutter::PluginRegistrar(registrar);
  plugins_menubar::MenubarPlugin::RegisterWithRegistrar(plugin_registrar);
}

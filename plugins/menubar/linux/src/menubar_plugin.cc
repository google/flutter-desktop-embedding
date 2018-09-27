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

#include <menubar/menubar_plugin.h>

#include <gtk/gtk.h>
#include <stdio.h>

#include "../../common/channel_constants.h"

static constexpr char kWindowTitle[] = "Flutter Menubar";

namespace plugins_menubar {
using flutter_desktop_embedding::JsonMethodCall;
using flutter_desktop_embedding::MethodResult;

MenuBarPlugin::MenuBarPlugin()
    : JsonPlugin(kChannelName, false), menubar_(nullptr) {}

MenuBarPlugin::~MenuBarPlugin() {}

// Class containing the implementation of the Menubar widget. This is currently
// a floating GTK window, separate from the main app. This is not the optimal
// solution.
class MenuBarPlugin::Menubar {
 public:
  explicit Menubar(MenuBarPlugin *parent) {
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
      menubar_window_ = nullptr;
    }
  }

  // Get the top level menubar widget.
  GtkWidget *GetRootMenuBar() { return menubar_; }

  static void MenuItemSelected(GtkWidget *menuItem, gpointer *data) {
    auto plugin = reinterpret_cast<MenuBarPlugin *>(data);

    plugin->InvokeMethod(kMenuItemSelectedCallbackMethod,
                         std::stoi(gtk_widget_get_name(menuItem)));
  }

  // Create the menu items heirarchy from a given Json object.
  void SetMenuItems(const Json::Value &root,
                    flutter_desktop_embedding::Plugin *plugin,
                    GtkWidget *parentWidget) {
    if (root.isArray()) {
      // This is the base of Json tree. It's not a menu item itself, so there's
      // no need to create a widget.
      unsigned int counter = 0;
      while (counter < root.size()) {
        if (root[counter].isObject()) {
          SetMenuItems(root[counter], plugin, parentWidget);
          counter++;
        }
      }
      gtk_widget_show_all(menubar_window_);

      return;
    }

    if ((root[kLabelKey]).isString()) {
      std::string label = root[kLabelKey].asString();

      if (root[kChildrenKey].isArray()) {
        // A parent menu item. Create a widget with its label and then build the
        // children.
        auto array = root[kChildrenKey];
        auto menu = gtk_menu_new();
        auto menuItem = gtk_menu_item_new_with_label(label.c_str());

        if (root[kEnabledKey].isBool()) {
          gtk_widget_set_sensitive(menuItem, root[kEnabledKey].asBool());
        }
        gtk_menu_item_set_submenu(GTK_MENU_ITEM(menuItem), menu);
        gtk_menu_shell_append(GTK_MENU_SHELL(parentWidget), menuItem);

        SetMenuItems(array, plugin, menu);
      } else {
        // A leaf menu item. Only these items will have a callback.
        auto menuItem = gtk_menu_item_new_with_label(label.c_str());
        if (root[kEnabledKey].isBool()) {
          gtk_widget_set_sensitive(menuItem, root[kEnabledKey].asBool());
        }
        if (root[kIdKey].asInt()) {
          std::string idString = std::to_string(root[kIdKey].asInt());
          gtk_widget_set_name(menuItem, idString.c_str());
        }
        g_signal_connect(G_OBJECT(menuItem), "activate",
                         G_CALLBACK(MenuItemSelected), plugin);
        gtk_menu_shell_append(GTK_MENU_SHELL(parentWidget), menuItem);
      }
    }

    if (root.get(kDividerKey, false).asBool()) {
      auto separator = gtk_separator_menu_item_new();
      gtk_menu_shell_append(GTK_MENU_SHELL(parentWidget), separator);
    }
    gtk_widget_show_all(menubar_window_);
  }

  // Remove all items from the menubar.
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

void MenuBarPlugin::HandleJsonMethodCall(const JsonMethodCall &method_call,
                                         std::unique_ptr<MethodResult> result) {
  if (method_call.method_name().compare(kMenuSetMethod) == 0) {
    result->Success();
    if (menubar_ == nullptr) {
      menubar_ = std::make_unique<MenuBarPlugin::Menubar>(this);
    }
    // The menubar will be redrawn after every interaction. Clear items to avoid
    // duplication.
    menubar_->ClearMenuItems();
    menubar_->SetMenuItems(method_call.GetArgumentsAsJson(), this,
                           menubar_->GetRootMenuBar());
  } else {
    result->NotImplemented();
  }
}

}  // namespace plugins_menubar
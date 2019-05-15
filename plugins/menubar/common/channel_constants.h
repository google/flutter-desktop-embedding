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
#ifndef PLUGINS_MENUBAR_COMMON_CHANNEL_CONSTANTS_H_
#define PLUGINS_MENUBAR_COMMON_CHANNEL_CONSTANTS_H_

namespace plugins_menubar {

// This file contains constants used in the platform channel, which are shared
// across all native platform implementations.

// The name of the plugin's platform channel.
extern const char kChannelName[];

// The method name to instruct the native plugin to set the menu.
//
// The argument to this method will be an array of map representations
// of menus that should be set as top-level menu items.
extern const char kMenuSetMethod[];
// The method name for the Dart-side callback called when a menu item is
// selected.
//
// The argument to this method must be the ID of the selected menu item, as
// provided in the kIdKey field in the kMenuSetMethod call.
extern const char kMenuItemSelectedCallbackMethod[];

// Keys for the map representations of menus sent to kMenuSetMethod.

// The ID of the menu item, as an integer. If present, this indicates that the
// menu item should trigger a kMenuItemSelectedCallbackMethod call when
// selected.
extern const char kIdKey[];

// The label that should be displayed for the menu, as a string.
extern const char kLabelKey[];

// Whether or not the menu item should be enabled, as a boolean. If not present
// the defualt is to enabled the item.
extern const char kEnabledKey[];

// Menu items that should be shown as a submenu of this item, as an array.
extern const char kChildrenKey[];

// Whether or not the menu item is a divider, as a boolean. If true, no other
// keys will be present.
extern const char kDividerKey[];

}  // namespace plugins_menubar

#endif  // PLUGINS_MENUBAR_COMMON_CHANNEL_CONSTANTS_H_

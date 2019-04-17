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
#ifndef PLUGINS_COLOR_PANEL_COMMON_CHANNEL_CONSTANTS_H_
#define PLUGINS_COLOR_PANEL_COMMON_CHANNEL_CONSTANTS_H_

namespace plugins_color_panel {

// This file contains constants used in the platform channel, which are shared
// across all native platform implementations.

// The name of the plugin's platform channel.
extern const char kChannelName[];

// The method name to instruct the native plugin to show the panel.
extern const char kShowColorPanelMethod[];
// The method name to instruct the native plugin to hide the panel.
extern const char kHideColorPanelMethod[];
// The method name for the Dart-side callback that receives color values.
extern const char kColorSelectedCallbackMethod[];
// The method name for the Dart-side callback that is called if the panel is
// closed from the UI, rather than via a call to kHideColorPanelMethod.
extern const char kClosedCallbackMethod[];

// The argument to show an opacity modifier on the panel. Default is true.
extern const char kColorPanelShowAlpha[];

// Keys for the ARGB color map sent to kColorPanelCallback.
// The values should be numbers between 0 and 1. Native color pickers on
// macOS and Linux always return a value of 1 on the Alpha channel if the
// opacity slider is not shown.
extern const char kColorComponentAlphaKey[];
extern const char kColorComponentRedKey[];
extern const char kColorComponentGreenKey[];
extern const char kColorComponentBlueKey[];
}  // namespace plugins_color_panel

#endif  // PLUGINS_COLOR_PANEL_COMMON_CHANNEL_CONSTANTS_H_

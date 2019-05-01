// Copyright 2019 Google LLC
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
#ifndef PLUGINS_WINDOW_SIZE_COMMON_CHANNEL_CONSTANTS_H_
#define PLUGINS_WINDOW_SIZE_COMMON_CHANNEL_CONSTANTS_H_

namespace plugins_window_size {

// This file contains constants used in the platform channel, which are shared
// across all native platform implementations.

// The name of the plugin's platform channel.
extern const char kChannelName[];

// The method name to request information about the available screens.
//
// Returns a list of screen info maps; see keys below.
extern const char kGetScreenListMethod[];

// The method name to request information about the window containing the
// Flutter instance.
//
// Returns a list of window info maps; see keys below.
extern const char kGetWindowInfoMethod[];

// The method name to set the frame of a window.
//
// Takes a frame array, as documented for the value of kFrameKey.
extern const char kSetWindowFrameMethod[];

// Keys for screen and window maps returned by kGetScreenListMethod.

// The frame of a screen or window. The value is an array of four doubles:
//   [left, top, width, height]
extern const char kFrameKey[];

// The frame of a screen available for use by applications. The value format
// is the same as kFrameKey's.
//
// Only used for screens.
extern const char kVisibleFrameKey[];

// The scale factor for a screen or window, as a double.
//
// This is the number of pixels per screen coordinate, and thus the ratio
// between sizes as seen by Flutter and sizes in native screen coordinates.
extern const char kScaleFactorKey[];

// The screen containing this window, if any. The value is a screen map, or null
// if the window is not visible on a screen.
//
// Only used for windows.
//
// If a window is on multiple screens, it is up to the platform to decide which
// screen to report.
extern const char kScreenKey[];

}  // namespace plugins_window_size

#endif  // PLUGINS_WINDOW_SIZE_COMMON_CHANNEL_CONSTANTS_H_

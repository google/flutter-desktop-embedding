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

// Keys for screen maps returned by kGetScreenListMethod.

// The frame of the screen. The value is an array of four doubles:
//   [left, top, width, height]
extern const char kFrameKey[];
// The frame of the screen available for use by applications. The value format
// is the same as kFrameKey's.
extern const char kVisibleFrameKey[];
// The scale factor for the screen, as a double.
//
// This is the number of pixels per screen coordinate, and thus the ratio
// between sizes as seen by Flutter, and sizes in native screen coordinates.
extern const char kScaleFactorKey[];

}  // namespace plugins_window_size

#endif  // PLUGINS_WINDOW_SIZE_COMMON_CHANNEL_CONSTANTS_H_

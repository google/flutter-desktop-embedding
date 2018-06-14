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
#ifndef PLUGINS_FILE_CHOOSER_COMMON_CHANNEL_CONSTANTS_H_
#define PLUGINS_FILE_CHOOSER_COMMON_CHANNEL_CONSTANTS_H_

namespace plugins_file_chooser {

// This file contains constants used in the platform channel, which are shared
// across all native platform implementations.

// The name of the plugin's platform channel.
extern const char kChannelName[];

// The method name to instruct the native plugin to show an open panel.
extern const char kShowOpenPanelMethod[];
// The method name to instruct the native plugin to show a save panel.
extern const char kShowSavePanelMethod[];

// Configuration parameters for file chooser panels:

// The path, as a string, for initial directory to display. Default behavior is
// left to the OS if not provided.
extern const char kInitialDirectoryKey[];

// The initial file name that should appears in the file chooser. Defaults to an
// empty string if not provided.
extern const char kInitialFileNameKey[];

// An array of UTI or file extension strings a panel is allowed to choose.
extern const char kAllowedFileTypesKey[];

// The text that appears on the panel's confirmation button. If not provided,
// the OS default is used.
extern const char kConfirmButtonTextKey[];

// Configuration parameters from this point on apply only to open panels:

// A boolean indicating whether a panel should allow choosing multiple file
// paths. Defaults to false if not set.
extern const char kAllowsMultipleSelectionKey[];

// A boolean indicating whether a panel should allow choosing directories
// instead of files. Defaults to false if not set.
extern const char kCanChooseDirectoriesKey[];

}  // namespace plugins_file_chooser

#endif  // PLUGINS_FILE_CHOOSER_COMMON_CHANNEL_CONSTANTS_H_

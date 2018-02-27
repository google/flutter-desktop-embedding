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

#import <AppKit/AppKit.h>

#import "FLEPlugin.h"

/**
 * A FlutterPlugin to manage macOS's shared NSColorPanel singleton. Owned by
 * the FlutterViewController. Responsible for managing the panel's display state
 * and sending selected color data to Flutter, via system channels.
 */
@interface FLEColorPanelPlugin : NSObject<FLEPlugin>

@end

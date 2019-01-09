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

#import <Cocoa/Cocoa.h>

#import "FLEBinaryMessenger.h"
#import "FLEViewController.h"

/**
 * A plugin to handle text input.
 *
 * Responsible for bridging the native macOS text input system with the Flutter framework text
 * editing classes, via system channels.
 *
 * This is not an FLEPlugin since it needs access to FLEViewController internals, so needs to be
 * managed differently.
 */
@interface FLETextInputPlugin : NSResponder

/**
 * Initializes a text input plugin that coordinates key event handling with |viewController|.
 */
- (instancetype)initWithViewController:(FLEViewController*)viewController;

@end

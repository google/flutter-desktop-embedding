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
#import "FLEMethodChannel.h"

/**
 * The protocol for an object managing registration for a plugin. It provides access to application
 * context, as as allowing registering for callbacks for handling various conditions.
 *
 * Currently FLEPluginRegistrar has very limited functionality, but is expected to expand over time
 * to more closely match the functionality of FlutterPluginRegistrar.
 */
@protocol FLEPluginRegistrar <NSObject>

/**
 * The binary messenger used for creating channels to communicate with the Flutter engine.
 */
@property(nonnull, readonly) id<FLEBinaryMessenger> messenger;

/**
 * The view displaying Flutter content.
 *
 * WARNING: If/when multiple Flutter views within the same application are supported (#98), this
 * API will change.
 */
@property(nullable, readonly) NSView *view;

/**
 * Registers |delegate| to receive handleMethodCall:result: callbacks for the given |channel|.
 */
- (void)addMethodCallDelegate:(nonnull id<FLEPlugin>)delegate
                      channel:(nonnull FLEMethodChannel *)channel;

@end

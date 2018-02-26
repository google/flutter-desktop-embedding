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

@class FLEViewController;

/**
 * A plugin is an object that can respond appropriately to Flutter platform messages over a specific
 * named system channel. See https://flutter.io/platform-channels/.
 */
@protocol FLEPlugin

/**
 * A weak reference to the owning controller. May be used to send messages to the Flutter
 * framework.
 */
@property(nullable, weak) FLEViewController *controller;

/**
 * The name of the system channel via which this plugin communicates.
 */
@property(nonnull, readonly) NSString *channel;

/**
 * Handles the given platform message sent on the plugin's channel. Handling may involve
 * sending messages the other direction via [FlutterViewController.sendPlatformMessage].
 */
- (nullable id)handlePlatformMessage:(nonnull NSDictionary *)message;

@end

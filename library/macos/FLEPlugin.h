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

#import <Foundation/Foundation.h>

#import "FLEMethodCall.h"
#import "FLEMethodChannel.h"
#import "FLEMethodCodec.h"

@protocol FLEPluginRegistrar;

/**
 * Implemented by the platform side of a Flutter plugin.
 *
 * Defines a set of optional callback methods and a method to set up the plugin
 * and register it to be called by other application components.
 *
 * Currently FLEPlugin has very limited functionality, but is expected to expand over time to
 * more closely match the functionality of FlutterPlugin.
 */
@protocol FLEPlugin <NSObject>

/**
 * Creates an instance of the plugin to register with |registrar| using the desired
 * FLEPluginRegistrar methods.
 */
+ (void)registerWithRegistrar:(nonnull id<FLEPluginRegistrar>)registrar;

@optional

/**
 * Called when a message is sent from Flutter on a channel that a plugin instance has subscribed
 * to via -[FLEPluginRegistrar addMethodCallDelegate:channel:].
 *
 * The |result| callback must be called exactly once, with one of:
 * - FLEMethodNotImplemented, if the method call is unknown.
 * - An FLEMethodError, if the method call was understood but there was a
 *   problem handling it.
 * - Any other value (including nil) to indicate success. The value will
 *   be returned to the Flutter caller, and must be serializable to JSON.
 */
- (void)handleMethodCall:(nonnull FLEMethodCall *)call result:(nonnull FLEMethodResult)result;

@end

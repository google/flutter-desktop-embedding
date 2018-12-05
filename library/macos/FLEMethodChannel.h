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

#import "FLEBinaryMessenger.h"
#import "FLEMethodCodec.h"

/**
 * A method call result callback. Used for sending a method call's response back to the
 * Flutter engine. The result must be serializable by the codec used to encode the message.
 */
typedef void (^FLEMethodResult)(id _Nullable result);

/**
 * A handler for receiving a method call. Implementations should asynchronously call |result|
 * exactly once with the result of handling method the call, with one of:
 * - FLEMethodNotImplemented, if the method call is unknown.
 * - An FLEMethodError, if the method call was understood but there was a
 *   problem handling it.
 * - Any other value (including nil) to indicate success. The value will
 *   be returned to the Flutter caller.
 */
typedef void (^FLEMethodCallHandler)(FLEMethodCall *_Nonnull call, FLEMethodResult _Nonnull result);

/**
 * A constant that can be passed to an FLEMethodResult to indicate that the message is not handled
 * (e.g., the method name is unknown).
 */
extern NSString const *_Nonnull FLEMethodNotImplemented;

/**
 * A channel for communicating with the Flutter engine using invocation of asynchronous methods.
 */
@interface FLEMethodChannel : NSObject

// TODO: support +methodChannelWithName:binaryMessenger: once the standard codec is supported
// (Issue #67).

/**
 * Returns a new channel that sends and receives method calls on the channel named |name|, encoded
 * with |codec| and dispatched via |messenger|.
 */
+ (nonnull instancetype)methodChannelWithName:(nonnull NSString *)name
                              binaryMessenger:(nonnull id<FLEBinaryMessenger>)messenger
                                        codec:(nonnull id<FLEMethodCodec>)codec;

/**
 * Initializes a channel to send and receive method calls on the channel named |name|, encoded
 * with |codec| and dispatched via |messenger|.
 */
- (nonnull instancetype)initWithName:(nonnull NSString *)name
                     binaryMessenger:(nonnull id<FLEBinaryMessenger>)messenger
                               codec:(nonnull id<FLEMethodCodec>)codec;

/**
 * Sends a platform message to the Flutter engine on this channel.
 *
 * The arguments, if any, must be encodable using this channel's codec.
 */
- (void)invokeMethod:(nonnull NSString *)method arguments:(nullable id)arguments;

// TODO: Support invokeMethod:arguments:result: once
// https://github.com/flutter/flutter/issues/18852 is resolved

/**
 * Registers a handler that should be called any time a method call is received on this channel.
 */
- (void)setMethodCallHandler:(nullable FLEMethodCallHandler)handler;

@end

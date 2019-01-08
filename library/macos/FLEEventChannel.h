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
 * An event sink callback.
 *
 * @param event The event.
 */
typedef void (^FLEEventSink)(id _Nullable event);

/**
 * A constant used with `FLEEventChannel` to indicate end of stream.
 */
extern NSString const *_Nonnull FLEEndOfEventStream;

/**
 * A strategy for exposing an event stream to the Flutter side.
 */
@protocol FLEStreamHandler

/**
 * Sets up an event stream and begins emitting events.
 *
 * Invoked when the first listener is registered with the Stream associated to
 * this channel on the Flutter side.
 *
 * @param arguments Arguments for the stream.
 * @param events A callback to asynchronously emit events. Invoke the
 *     callback with a `FLEMethodError` to emit an error event. Invoke the
 *     callback with `FLEEndOfEventStream` to indicate that no more
 *     events will be emitted. Any other value, including `nil` are emitted as
 *     successful events.
 * @return A FLEMethodError instance, if setup fails.
 */
- (nullable FLEMethodError *)onListenWithArguments:(nullable id)arguments
                                         eventSink:(FLEEventSink _Nonnull)events;

/**
 * Tears down an event stream.
 *
 * Invoked when the last listener is deregistered from the Stream associated to
 * this channel on the Flutter side.
 *
 * The channel implementation may call this method with `nil` arguments
 * to separate a pair of two consecutive set up requests. Such request pairs
 * may occur during Flutter hot restart.
 *
 * @param arguments Arguments for the stream.
 * @return A FLEMethodError instance, if teardown fails.
 */
- (nullable FLEMethodError *)onCancelWithArguments:(nullable id)arguments;

@end

/**
 * A channel for communicating with the Flutter side using event streams.
 */
@interface FLEEventChannel : NSObject

/**
 * Creates a `FLEEventChannel` with the specified name and binary messenger.
 *
 * The channel name logically identifies the channel; identically named channels
 * interfere with each other's communication.
 *
 * The binary messenger is a facility for sending raw, binary messages to the
 * Flutter side.
 *
 * The channel uses `FLEMethodCodec` to decode stream setup and
 * teardown requests, and to encode event envelopes.
 *
 * @param name The channel name.
 * @param messenger The binary messenger.
 * @param codec The method codec.
 * @return A new channel.
 */
+ (nonnull instancetype)eventChannelWithName:(nonnull NSString *)name
                             binaryMessenger:(nonnull id<FLEBinaryMessenger>)messenger
                                       codec:(nonnull id<FLEMethodCodec>)codec;

/**
 * Registers a handler for stream setup requests from the Flutter side.
 *
 * Replaces any existing handler. Use a `nil` handler for unregistering the
 * existing handler.
 *
 * @param handler The stream handler.
 */
- (void)setStreamHandler:(nullable id<FLEStreamHandler>)handler;

@end

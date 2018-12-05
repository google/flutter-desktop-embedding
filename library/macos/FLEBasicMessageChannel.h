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
#import "FLEMessageCodec.h"

/**
 * A message response callback. Used for sending a message's reply back to the Flutter engine.
 * The reply must be serializable by the codec used to encode the message.
 */
typedef void (^FLEMessageReply)(id _Nullable reply);

/**
 * A handler for receiving a message. Implementations should asynchronously call |callback|
 * exactly once with the reply to the message (or nil if there is none).
 */
typedef void (^FLEMessageHandler)(id _Nullable message, FLEMessageReply _Nonnull callback);

/**
 * A channel for communicating with the Flutter engine by sending asynchronous messages.
 */
@interface FLEBasicMessageChannel : NSObject

// TODO: support +messageChannelWithName:binaryMessenger: once the standard codec is supported
// (Issue #67).

/**
 * Returns a new channel that sends and receives messages on the channel named |name|, encoded
 * with |codec| and dispatched via |messenger|.
 */
+ (nonnull instancetype)messageChannelWithName:(nonnull NSString *)name
                               binaryMessenger:(nonnull NSObject<FLEBinaryMessenger> *)messenger
                                         codec:(nonnull NSObject<FLEMessageCodec> *)codec;

/**
 * Initializes a channel to send and receive messages on the channel named |name|, encoded
 * with |codec| and dispatched via |messenger|.
 */
- (nonnull instancetype)initWithName:(nonnull NSString *)name
                     binaryMessenger:(nonnull NSObject<FLEBinaryMessenger> *)messenger
                               codec:(nonnull NSObject<FLEMessageCodec> *)codec;

/**
 * Sends a message to the Flutter engine on this channel.
 *
 * The message must be encodable using this channel's codec.
 */
- (void)sendMessage:(nullable id)message;

// TODO: Support sendMessage:result: once
// https://github.com/flutter/flutter/issues/18852 is resolved

/**
 * Registers a handler that should be called any time a message is received on this channel.
 */
- (void)setMessageHandler:(nullable FLEMessageHandler)handler;
@end

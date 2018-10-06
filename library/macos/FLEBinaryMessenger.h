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

/**
 * A message reply callback.
 *
 * Used for submitting a reply back to a Flutter message sender.
 */
typedef void (^FLEBinaryReply)(NSData *_Nullable reply);

/**
 * A message handler callback.
 *
 * Used for receiving messages from Flutter and providing an asynchronous reply.
 */
typedef void (^FLEBinaryMessageHandler)(NSData *_Nullable message, FLEBinaryReply _Nonnull reply);

/**
 * A protocol for a class that handles communication of binary data on named channels to and from
 * the Flutter engine.
 */
@protocol FLEBinaryMessenger <NSObject>

/**
 * Sends a binary message to the Flutter side on the specified channel, expecting
 * no reply.
 */
- (void)sendOnChannel:(nonnull NSString *)channel message:(nullable NSData *)message;

// TODO: Add support for sendOnChannel:message:binaryReply: once
// https://github.com/flutter/flutter/issues/18852 is fixed.

/**
 * Registers a message handler for incoming binary messages from the Flutter side
 * on the specified channel.
 *
 * Replaces any existing handler. Provide a nil handler to unregister the existing handler.
 */
- (void)setMessageHandlerOnChannel:(nonnull NSString *)channel
              binaryMessageHandler:(nullable FLEBinaryMessageHandler)handler;
@end

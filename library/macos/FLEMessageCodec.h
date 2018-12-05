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
 * Translates between a binary message and higher-level message objects.
 */
@protocol FLEMessageCodec

/**
 * Returns the shared instance of the codec.
 */
+ (nonnull instancetype)sharedInstance;

/**
 * Returns a binary encoding of the given |message|, or nil if the message cannot be
 * serialized by this codec.
 */
- (nullable NSData*)encode:(nullable id)message;

/**
 * Returns the decoded mesasge, or nil if it cannot be decoded.
 */
- (nullable id)decode:(nullable NSData*)messageData;

@end

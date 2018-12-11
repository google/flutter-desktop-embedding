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
#import "FLEMethodError.h"

/**
 * Translates between a binary message and higher-level method call and response/error objects.
 */
@protocol FLEMethodCodec

/**
 * Returns the shared instance of the codec.
 */
+ (nonnull instancetype)sharedInstance;

/**
 * Returns a binary encoding of the given |methodCall|, or nil if the method call cannot be
 * serialized by this codec.
 */
- (nullable NSData*)encodeMethodCall:(nonnull FLEMethodCall*)methodCall;

/**
 * Returns the FLEMethodCall encoded in |methodData|, or nil if it cannot be decoded.
 */
- (nullable FLEMethodCall*)decodeMethodCall:(nonnull NSData*)methodData;

/**
 * Returns a binary encoding of |result|. Returns nil if |result| is not a type supported by the
 * codec.
 */
- (nullable NSData*)encodeSuccessEnvelope:(nullable id)result;

/**
 * Returns a binary encoding of |error|. Returns nil if the |details| parameter of |error| is not
 * a type supported by the codec.
 */
- (nullable NSData*)encodeErrorEnvelope:(nonnull FLEMethodError*)error;

@end

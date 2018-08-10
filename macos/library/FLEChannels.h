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
 * An object encapsulating a method call from Flutter.
 */
@interface FLEMethodCall : NSObject

/**
 * Initializes an FLEMethodCall. If |arguments| is provided, it must be serializable to JSON.
 */
- (nonnull instancetype)initWithMethodName:(nonnull NSString *)name
                                 arguments:(nullable id)arguments NS_DESIGNATED_INITIALIZER;
- (nonnull instancetype)init NS_UNAVAILABLE;

/**
 * The name of the method being called.
 */
@property(readonly, nonatomic, nonnull) NSString *methodName;

/**
 * The arguments to the method being called, if any.
 *
 * This object must be serializable to JSON. See
 * https://docs.flutter.io/flutter/services/JSONMethodCodec-class.html
 * for supported types.
 */
@property(readonly, nonatomic, nullable) id arguments;

@end

#pragma mark -

/**
 * A method call result callback. Used for sending a method call's response back to the
 * Flutter engine. The result must be serializable to JSON.
 */
typedef void (^FLEMethodResult)(id _Nullable result);

/**
 * A constant that can be passed to an FLEMethodResult to indicate that the message is not handled
 * (e.g., the method name is unknown).
 */
extern NSString const *_Nonnull FLEMethodNotImplemented;

/**
 * An error object that can be passed to an FLEMethodResult to send an error response to the caller
 * on the Flutter side.
 */
@interface FLEMethodError : NSObject

/**
 * Initializes an FLEMethodError. If |details| is provided, it must be serializable to JSON.
 */
- (nonnull instancetype)initWithCode:(nonnull NSString *)code
                             message:(nullable NSString *)message
                             details:(nullable id)details NS_DESIGNATED_INITIALIZER;
- (nonnull instancetype)init NS_UNAVAILABLE;

/**
 * The error code, as a string.
 */
@property(readonly, nonatomic, nonnull) NSString *code;

/**
 * A human-readable description of the error.
 */
@property(readonly, nonatomic, nullable) NSString *message;

/**
 * Any additional details or context about the error.
 *
 * This object must be serializable to JSON.
 */
@property(readonly, nonatomic, nullable) id details;

@end

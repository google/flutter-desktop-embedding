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
 * Initializes an FLEMethodCall. If |arguments| is provided, it must be serializable by the codec
 * used to encode the call.
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
 * This object must be serializable by the codec used to encode the call.
 */
@property(readonly, nonatomic, nullable) id arguments;

@end

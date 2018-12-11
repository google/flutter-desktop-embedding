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

#import "FLEJSONMethodCodec.h"

// Keys for JSON-encoded method calls.
static NSString *const kMessageMethodKey = @"method";
static NSString *const kMessageArgumentsKey = @"args";

/**
 * Returns the JSON serialiazation of |object|. If |object| is not serializable to JSON, logs an
 * error and returns nil.
 */
static NSData *SerializeAsJSON(id object) {
  if (![NSJSONSerialization isValidJSONObject:object]) {
    NSLog(@"Error: Unable to construct a valid JSON object from %@", object);
    return nil;
  }

  NSError *error = nil;
  NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
  if (error) {
    NSLog(@"Error: Failed to create JSON message for %@: %@", object, error.debugDescription);
  }
  return data;
}

// See the documentation for the Dart JSONMethodCodec class for the JSON structures used by this
// this class.
@implementation FLEJSONMethodCodec

#pragma mark FLEMethodCodec

+ (instancetype)sharedInstance {
  static FLEJSONMethodCodec *sharedInstance;
  if (!sharedInstance) {
    sharedInstance = [[FLEJSONMethodCodec alloc] init];
  }
  return sharedInstance;
}

- (NSData *)encodeMethodCall:(FLEMethodCall *)methodCall {
  return SerializeAsJSON(@{
    kMessageMethodKey : methodCall.methodName,
    kMessageArgumentsKey : methodCall.arguments ?: [NSNull null],
  });
}

- (FLEMethodCall *)decodeMethodCall:(NSData *)methodData {
  NSDictionary *message = [NSJSONSerialization JSONObjectWithData:methodData options:0 error:NULL];
  NSString *method = message[kMessageMethodKey];
  if (!method) {
    return nil;
  }
  id arguments = message[kMessageArgumentsKey];
  if (arguments == [NSNull null]) {
    arguments = nil;
  }
  return [[FLEMethodCall alloc] initWithMethodName:method arguments:arguments];
}

- (NSData *)encodeSuccessEnvelope:(id)result {
  return SerializeAsJSON(@[ result ?: [NSNull null] ]);
}

- (NSData *)encodeErrorEnvelope:(FLEMethodError *)error {
  return SerializeAsJSON(@[
    error.code,
    error.message ?: [NSNull null],
    error.details ?: [NSNull null],
  ]);
}

@end

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

#import "FLEChannels.h"

NSString const *FLEMethodNotImplemented = @"notimplemented";

static NSString *const kMessageMethodKey = @"method";
static NSString *const kMessageArgumentsKey = @"args";

@implementation FLEMethodCall

+ (nullable instancetype)methodCallFromMessage:(nonnull NSDictionary *)message {
  NSString *method = message[kMessageMethodKey];
  if (!method) {
    return nil;
  }
  id arguments = message[kMessageArgumentsKey];
  if (arguments == [NSNull null]) {
    arguments = nil;
  }
  return [[self alloc] initWithMethodName:method arguments:arguments];
}

- (nonnull instancetype)initWithMethodName:(nonnull NSString *)name
                                 arguments:(nullable id)arguments {
  self = [super init];
  if (self) {
    _methodName = name;
    _arguments = arguments;
  }
  return self;
}

- (nonnull NSDictionary *)asMessage {
  return @{
    kMessageMethodKey : _methodName,
    kMessageArgumentsKey : _arguments ?: [NSNull null],
  };
}

@end

#pragma mark -

@implementation FLEMethodError

- (nonnull instancetype)initWithCode:(nonnull NSString *)code
                             message:(nullable NSString *)message
                             details:(nullable id)details {
  self = [super init];
  if (self) {
    _code = code;
    _message = message;
    _details = details;
  }
  return self;
}

@end

#pragma mark -

NSData *EngineResponseForMethodResult(id result) {
  // The engine expects one of three responses to a platform message:
  // - No data, indicating that the method is not implemented.
  // - A one-element array indicating succes, with the response payload as the element.
  // - A three-element array indicating an error, consisting of:
  //   * An error code string.
  //   * An optional human-readable error string.
  //   * An optional object with more error information.
  NSArray *responseObject = nil;
  if (result == FLEMethodNotImplemented) {
    // Note that the compare above deliberately uses pointer equality rather than string equality
    // since only the constant itself should be treated as 'not implemented'.
    return nil;
  } else if ([result isKindOfClass:[FLEMethodError class]]) {
    FLEMethodError *error = (FLEMethodError *)result;
    responseObject = @[
      error.code,
      error.message ?: [NSNull null],
      error.details ?: [NSNull null],
    ];
  } else {
    responseObject = @[ result ?: [NSNull null] ];
  }
  return [NSJSONSerialization dataWithJSONObject:responseObject options:0 error:NULL];
}

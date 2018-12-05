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

#import "FLEMethodChannel.h"

NSString const *FLEMethodNotImplemented = @"notimplemented";

@implementation FLEMethodChannel {
  NSString *_name;
  __weak id<FLEBinaryMessenger> _messenger;
  id<FLEMethodCodec> _codec;
}

+ (instancetype)methodChannelWithName:(NSString *)name
                      binaryMessenger:(id<FLEBinaryMessenger>)messenger
                                codec:(NSObject<FLEMethodCodec> *)codec {
  return [[[self class] alloc] initWithName:name binaryMessenger:messenger codec:codec];
}

- (instancetype)initWithName:(NSString *)name
             binaryMessenger:(id<FLEBinaryMessenger>)messenger
                       codec:(id<FLEMethodCodec>)codec {
  self = [super init];
  if (self) {
    _name = [name copy];
    _messenger = messenger;
    _codec = codec;
  }
  return self;
}

- (void)invokeMethod:(NSString *)method arguments:(id)arguments {
  FLEMethodCall *methodCall = [[FLEMethodCall alloc] initWithMethodName:method arguments:arguments];
  NSData *message = [_codec encodeMethodCall:methodCall];
  if (!message) {
    NSLog(@"Error: Unable to construct a message to call %@ on %@", method, _name);
    return;
  }
  [_messenger sendOnChannel:_name message:message];
}

- (void)setMethodCallHandler:(FLEMethodCallHandler)handler {
  if (!handler) {
    [_messenger setMessageHandlerOnChannel:_name binaryMessageHandler:nil];
    return;
  }

  // Don't capture the channel in the callback, since that makes lifetimes harder to reason about.
  id<FLEMethodCodec> codec = _codec;
  NSString *channelName = _name;

  FLEBinaryMessageHandler messageHandler = ^(NSData *message, FLEBinaryReply callback) {
    FLEMethodCall *methodCall = [codec decodeMethodCall:message];
    if (!methodCall) {
      NSLog(@"Received invalid method call on channel %@", channelName);
      callback(nil);
      return;
    }
    handler(methodCall, ^(id result) {
      if (result == FLEMethodNotImplemented) {
        callback(nil);
      } else if ([result isKindOfClass:[FLEMethodError class]]) {
        callback([codec encodeErrorEnvelope:(FLEMethodError *)result]);
      } else {
        callback([codec encodeSuccessEnvelope:result]);
      }
    });
  };

  [_messenger setMessageHandlerOnChannel:_name binaryMessageHandler:messageHandler];
}

@end

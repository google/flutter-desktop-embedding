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

#import "FLEEventChannel.h"

NSString const *FLEEndOfEventStream = @"EndOfEventStream";

@implementation FLEEventChannel {
  NSString *_name;
  __weak id<FLEBinaryMessenger> _messenger;
  id<FLEMethodCodec> _codec;
}

+ (instancetype)eventChannelWithName:(NSString *)name
                     binaryMessenger:(id<FLEBinaryMessenger>)messenger
                               codec:(id<FLEMethodCodec>)codec {
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

- (void)setStreamHandler:(NSObject<FLEStreamHandler> *)handler {
  if (!handler) {
    [_messenger setMessageHandlerOnChannel:_name binaryMessageHandler:nil];
    return;
  }

  id<FLEMethodCodec> codec = _codec;
  __weak id<FLEBinaryMessenger> messenger = _messenger;
  NSString *name = _name;
  FLEEventSink eventSink = ^(id event) {
    if (event == FLEEndOfEventStream) {
      [messenger sendOnChannel:name message:nil];
    } else if ([event isKindOfClass:[FLEMethodError class]]) {
      [messenger sendOnChannel:name message:[codec encodeErrorEnvelope:(FLEMethodError *)event]];
    } else {
      [messenger sendOnChannel:name message:[codec encodeSuccessEnvelope:event]];
    }
  };

  __block FLEEventSink currentSink = nil;
  FLEBinaryMessageHandler messageHandler = ^(NSData *message, FLEBinaryReply callback) {
    FLEMethodCall *call = [codec decodeMethodCall:message];
    if ([call.methodName isEqual:@"listen"]) {
      if (currentSink) {
        FLEMethodError *error = [handler onCancelWithArguments:nil];
        if (error) {
          NSLog(@"Failed to cancel existing stream: %@. %@ (%@)", error.code, error.message,
                error.details);
        }
      }
      currentSink = eventSink;
      FLEMethodError *error = [handler onListenWithArguments:call.arguments eventSink:currentSink];
      if (error) {
        callback([codec encodeErrorEnvelope:error]);
      } else {
        callback([codec encodeSuccessEnvelope:nil]);
      }
    } else if ([call.methodName isEqual:@"cancel"]) {
      if (!currentSink) {
        callback([codec
            encodeErrorEnvelope:[[FLEMethodError alloc] initWithCode:@"error"
                                                             message:@"No active stream to cancel"
                                                             details:nil]]);
        return;
      }
      currentSink = nil;
      FLEMethodError *error = [handler onCancelWithArguments:call.arguments];
      if (error) {
        callback([codec encodeErrorEnvelope:error]);
      } else {
        callback([codec encodeSuccessEnvelope:nil]);
      }
    } else {
      callback(nil);
    }
  };
  [_messenger setMessageHandlerOnChannel:_name binaryMessageHandler:messageHandler];
}

@end

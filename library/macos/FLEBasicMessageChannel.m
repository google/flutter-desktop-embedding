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

#import "FLEBasicMessageChannel.h"

@implementation FLEBasicMessageChannel {
  NSString *_name;
  __weak id<FLEBinaryMessenger> _messenger;
  id<FLEMessageCodec> _codec;
}
+ (instancetype)messageChannelWithName:(NSString *)name
                       binaryMessenger:(NSObject<FLEBinaryMessenger> *)messenger
                                 codec:(NSObject<FLEMessageCodec> *)codec {
  return [[[self class] alloc] initWithName:name binaryMessenger:messenger codec:codec];
}

- (instancetype)initWithName:(NSString *)name
             binaryMessenger:(NSObject<FLEBinaryMessenger> *)messenger
                       codec:(NSObject<FLEMessageCodec> *)codec {
  self = [super init];
  if (self) {
    _name = [name copy];
    _messenger = messenger;
    _codec = codec;
  }
  return self;
}

- (void)sendMessage:(id)message {
  [_messenger sendOnChannel:_name message:[_codec encode:message]];
}

- (void)setMessageHandler:(FLEMessageHandler)handler {
  if (!handler) {
    [_messenger setMessageHandlerOnChannel:_name binaryMessageHandler:nil];
    return;
  }

  // Don't capture the channel in the callback, since that makes lifetimes harder to reason about.
  id<FLEMessageCodec> codec = _codec;

  FLEBinaryMessageHandler messageHandler = ^(NSData *message, FLEBinaryReply callback) {
    handler([codec decode:message], ^(id reply) {
      callback([codec encode:reply]);
    });
  };

  [_messenger setMessageHandlerOnChannel:_name binaryMessageHandler:messageHandler];
}

@end

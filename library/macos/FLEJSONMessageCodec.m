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

#import "FLEJSONMessageCodec.h"

@implementation FLEJSONMessageCodec

+ (instancetype)sharedInstance {
  static FLEJSONMessageCodec *sharedInstance;
  if (!sharedInstance) {
    sharedInstance = [[FLEJSONMessageCodec alloc] init];
  }
  return sharedInstance;
}

- (NSData *)encode:(id)message {
  if (!message) {
    return nil;
  }

  NSData *encoding;
  NSError *error = nil;
  if ([message isKindOfClass:[NSArray class]] || [message isKindOfClass:[NSDictionary class]]) {
    encoding = [NSJSONSerialization dataWithJSONObject:message options:0 error:&error];
  } else {
    // Wrap then unwrap non-collection objects; see FlutterCodecs.mm in the Flutter engine.
    encoding = [NSJSONSerialization dataWithJSONObject:@[ message ] options:0 error:&error];
    const NSUInteger kJSONArrayStartLength = 1;
    const NSUInteger kJSONArrayEndLength = 1;
    encoding = [encoding subdataWithRange:NSMakeRange(kJSONArrayStartLength,
                                                      encoding.length - (kJSONArrayStartLength +
                                                                         kJSONArrayEndLength))];
  }
  if (error) {
    NSLog(@"Error: Failed to create JSON message for %@: %@", message, error.debugDescription);
  }
  return encoding;
}

// See FlutterCodecs.mm in the Flutter engine for implementation notes.
- (id)decode:(NSData *)messageData {
  if (!messageData) {
    return nil;
  }

  NSError *error = nil;
  id message = [NSJSONSerialization JSONObjectWithData:messageData
                                               options:NSJSONReadingAllowFragments
                                                 error:&error];
  if (error) {
    NSLog(@"Error: Failed to decode JSON message: %@", error.debugDescription);
  }
  return message;
}

@end

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

#import "FLEViewController.h"

@interface FLEViewController ()

/**
 * Adds a responder for keyboard events. Key up and key down events are forwarded to all added
 * responders.
 */
- (void)addKeyResponder:(nonnull NSResponder *)responder;

/**
 * Removes a responder for keyboard events.
 */
- (void)removeKeyResponder:(nonnull NSResponder *)responder;

/**
 * Sends a platform message to the Flutter engine on the given channel.
 * @param message The raw message.
 */
- (void)dispatchMessage:(nonnull NSDictionary *)message onChannel:(nonnull NSString *)channel;

@end

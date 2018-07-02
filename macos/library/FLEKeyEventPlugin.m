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
#import "FLEViewController+Internal.h"
#import "FLEKeyEventPlugin.h"

static NSString *const kKeyEventChannel = @"flutter/keyevent";

@implementation FLEKeyEventPlugin

@synthesize controller = _controller;

- (NSString *)channel {
  return kKeyEventChannel;
}

- (void)handleMethodCall:(FLEMethodCall *)call result:(FLEMethodResult)result {
  result(FLEMethodNotImplemented);
}

- (void)dispatchKeyEvent:(NSString *)type event:(NSEvent *)event {
  // TODO: Do not use 'android'. Reconsider when https://github.com/google/flutter-desktop-embedding/issues/47 is solved.
  NSDictionary* message = @{
                            @"keymap": @"android",
                            @"type": type,
                            @"keyCode": @(event.keyCode),
                            };
  
  [self.controller dispatchMessage:message onChannel:kKeyEventChannel];
}

#pragma mark - NSResponder

- (void)keyDown:(NSEvent *)event {
  [self dispatchKeyEvent:@"keydown" event:event];
}

- (void)keyUp:(NSEvent *)event {
  [self dispatchKeyEvent:@"keyup" event:event];
}

@end

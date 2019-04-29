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

#import "FLEWindowSizePlugin.h"

#import <AppKit/AppKit.h>

#include "plugins/window_size/common/channel_constants.h"

@implementation FLEWindowSizePlugin {
  // The channel used to communicate with Flutter.
  FlutterMethodChannel *_channel;
}

+ (void)registerWithRegistrar:(id<FLEPluginRegistrar>)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@(plugins_window_size::kChannelName)
                                  binaryMessenger:registrar.messenger];
  FLEWindowSizePlugin *instance = [[FLEWindowSizePlugin alloc] initWithChannel:channel];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithChannel:(FlutterMethodChannel *)channel {
  self = [super init];
  if (self) {
    _channel = channel;
  }
  return self;
}

/**
 * Handles platform messages generated by the Flutter framework on the color
 * panel channel.
 */
- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  id methodResult = nil;
  if ([call.method isEqualToString:@(plugins_window_size::kGetScreenListMethod)]) {
    NSMutableArray<NSDictionary *> *screenList =
        [NSMutableArray arrayWithCapacity:[NSScreen screens].count];
    for (NSScreen *screen in [NSScreen screens]) {
      NSRect frame = screen.frame;
      NSRect visibleFrame = screen.visibleFrame;
      [screenList addObject:@{
        @(plugins_window_size::kFrameKey) :
            @[ @(frame.origin.x), @(frame.origin.y), @(frame.size.width), @(frame.size.height) ],
        @(plugins_window_size::kVisibleFrameKey) : @[
          @(visibleFrame.origin.x), @(visibleFrame.origin.y), @(visibleFrame.size.width),
          @(visibleFrame.size.height)
        ],
        @(plugins_window_size::kScaleFactorKey) : @(screen.backingScaleFactor),
      }];
    }
    methodResult = screenList;
  } else {
    methodResult = FlutterMethodNotImplemented;
  }
  result(methodResult);
}

@end

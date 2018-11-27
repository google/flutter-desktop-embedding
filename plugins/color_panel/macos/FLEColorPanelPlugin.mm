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

#import "FLEColorPanelPlugin.h"

#import <AppKit/AppKit.h>

#include "plugins/color_panel/common/channel_constants.h"

@implementation FLEColorPanelPlugin

@synthesize controller = _controller;

- (NSString *)channel {
  return @(plugins_color_panel::kChannelName);
}

/**
 * Handles platform messages generated by the Flutter framework on the color
 * panel channel.
 */
- (void)handleMethodCall:(FLEMethodCall *)call result:(FLEMethodResult)result {
  BOOL handled = YES;
  if ([call.methodName isEqualToString:@(plugins_color_panel::kShowColorPanelMethod)]) {
    BOOL showAlpha = YES;
    if ([call.arguments isKindOfClass:[NSDictionary class]]) {
      showAlpha = [[call.arguments valueForKey:@(plugins_color_panel::kColorPanelShowAlpha)]
                   boolValue];
    }
    [self showColorPanel:showAlpha];
  } else if ([call.methodName isEqualToString:@(plugins_color_panel::kHideColorPanelMethod)]) {
    [self hideColorPanel];
  } else {
    handled = NO;
  }
  // Send an immediate empty success message for handled messages, since the actual color data
  // will be provided in follow-up messages.
  result(handled ? nil : FLEMethodNotImplemented);
}

/**
 * Configures the shared instance of NSColorPanel and makes it the frontmost & key window.
 */
- (void)showColorPanel:(BOOL)showAlpha {
  NSColorPanel *sharedColor = [NSColorPanel sharedColorPanel];
  sharedColor.delegate = self;
  [sharedColor setShowsAlpha:showAlpha];
  [sharedColor setTarget:self];
  [sharedColor setAction:@selector(selectedColorDidChange)];
  if (!sharedColor.isKeyWindow) {
    [sharedColor makeKeyAndOrderFront:nil];
  }
}

/**
 * Closes the shared color panel.
 */
- (void)hideColorPanel {
  if (![NSColorPanel sharedColorPanelExists]) {
    return;
  }

  // Disconnect before closing to prevent invoking the close callback.
  [self removeColorPanelConnections];

  NSColorPanel *sharedColor = [NSColorPanel sharedColorPanel];
  [sharedColor close];
}

/**
 * Removes the connections from the shared color panel back to this instance.
 */
- (void)removeColorPanelConnections {
  NSColorPanel *sharedColor = [NSColorPanel sharedColorPanel];
  [sharedColor setTarget:nil];
  [sharedColor setAction:nil];
  sharedColor.delegate = nil;
}

/**
 * Called when the user selects a color in the color panel. Grabs the selected color from the
 * panel and sends it to Flutter via the '_controller'.
 */
- (void)selectedColorDidChange {
  NSColor *color = [NSColorPanel sharedColorPanel].color;
  NSDictionary *colorDictionary = [self dictionaryWithColor:color];
  [_controller invokeMethod:@(plugins_color_panel::kColorSelectedCallbackMethod)
                  arguments:colorDictionary
                  onChannel:@(plugins_color_panel::kChannelName)];
}

/**
 * Converts an instance of NSColor to a dictionary representation suitable for JSON messages.
 *
 * @param color An instance of NSColor.
 * @return An instance of NSDictionary representing the color.
 */
- (NSDictionary *)dictionaryWithColor:(NSColor *)color {
  NSMutableDictionary *result = [NSMutableDictionary dictionary];
  result[@(plugins_color_panel::kColorComponentRedKey)] = @(color.redComponent);
  result[@(plugins_color_panel::kColorComponentGreenKey)] = @(color.greenComponent);
  result[@(plugins_color_panel::kColorComponentBlueKey)] = @(color.blueComponent);
  return result;
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification {
  [self removeColorPanelConnections];
  [_controller invokeMethod:@(plugins_color_panel::kClosedCallbackMethod)
                  arguments:nil
                  onChannel:@(plugins_color_panel::kChannelName)];
}

@end

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

#import "ColorPanelPlugin.h"

#import <AppKit/AppKit.h>

// See color_panel.dart for descriptions.
static NSString *const kChannelName = @"flutter/colorpanel";
static NSString *const kShowColorPanelMethod = @"ColorPanel.Show";
static NSString *const kColorPanelShowAlpha = @"ColorPanel.ShowAlpha";
static NSString *const kHideColorPanelMethod = @"ColorPanel.Hide";
static NSString *const kColorSelectedCallbackMethod = @"ColorPanel.ColorSelectedCallback";
static NSString *const kClosedCallbackMethod = @"ColorPanel.ClosedCallback";
static NSString *const kColorComponentAlphaKey = @"alpha";
static NSString *const kColorComponentRedKey = @"red";
static NSString *const kColorComponentGreenKey = @"green";
static NSString *const kColorComponentBlueKey = @"blue";

@implementation FLEColorPanelPlugin {
  // The channel used to communicate with Flutter.
  FlutterMethodChannel *_channel;
}

+ (void)registerWithRegistrar:(id<FlutterPluginRegistrar>)registrar {
  FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:kChannelName
                                                              binaryMessenger:registrar.messenger];
  FLEColorPanelPlugin *instance = [[FLEColorPanelPlugin alloc] initWithChannel:channel];
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
  if ([call.method isEqualToString:kShowColorPanelMethod]) {
    if ([call.arguments isKindOfClass:[NSDictionary class]]) {
      BOOL showAlpha = [[call.arguments valueForKey:kColorPanelShowAlpha] boolValue];
      [self showColorPanelWithAlpha:showAlpha];
    } else {
      NSString *errorString = [NSString
          stringWithFormat:@"Malformed call for %@. Expected an NSDictionary but got %@",
                           kShowColorPanelMethod, NSStringFromClass([call.arguments class])];
      methodResult = [FlutterError errorWithCode:@"Bad arguments" message:errorString details:nil];
    }
  } else if ([call.method isEqualToString:kHideColorPanelMethod]) {
    [self hideColorPanel];
  } else {
    methodResult = FlutterMethodNotImplemented;
  }
  // If no errors are generated, send an immediate empty success message for handled messages, since
  // the actual color data will be provided in follow-up messages.
  result(methodResult);
}

/**
 * Configures the shared instance of NSColorPanel and makes it the frontmost & key window.
 */
- (void)showColorPanelWithAlpha:(BOOL)showAlpha {
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
 * panel and sends it to Flutter via the '_channel'.
 */
- (void)selectedColorDidChange {
  NSColor *color = [NSColorPanel sharedColorPanel].color;
  NSDictionary *colorDictionary = [self dictionaryWithColor:color];
  [_channel invokeMethod:kColorSelectedCallbackMethod arguments:colorDictionary];
}

/**
 * Converts an instance of NSColor to a dictionary representation suitable for Flutter channel
 * messages.
 *
 * @param color An instance of NSColor.
 * @return An instance of NSDictionary representing the color.
 */
- (NSDictionary *)dictionaryWithColor:(NSColor *)color {
  NSMutableDictionary *result = [NSMutableDictionary dictionary];
  // TODO: Consider being able to pass other type of color space (Gray scale, CMYK, etc).
  NSColor *rgbColor = [color colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]];
  result[kColorComponentAlphaKey] = @(rgbColor.alphaComponent);
  result[kColorComponentRedKey] = @(rgbColor.redComponent);
  result[kColorComponentGreenKey] = @(rgbColor.greenComponent);
  result[kColorComponentBlueKey] = @(rgbColor.blueComponent);
  return result;
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification {
  [self removeColorPanelConnections];
  [_channel invokeMethod:kClosedCallbackMethod arguments:nil];
}

@end

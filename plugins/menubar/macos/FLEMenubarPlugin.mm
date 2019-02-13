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

#import "FLEMenubarPlugin.h"

#include "plugins/menubar/common/channel_constants.h"

@implementation FLEMenubarPlugin {
  // The channel used to communicate with Flutter.
  FlutterMethodChannel *_channel;
}

- (instancetype)initWithChannel:(FlutterMethodChannel *)channel {
  self = [super init];
  if (self) {
    _channel = channel;
  }
  return self;
}

/**
 * Removes any top-level menus added by this plugin.
 */
- (void)removeFlutterMenus {
  NSMenu *mainMenu = NSApp.mainMenu;
  // Remove in reverse order to simplify iteration while removing.
  for (NSInteger i = mainMenu.numberOfItems - 1; i >= 0; --i) {
    if ([mainMenu itemAtIndex:i].representedObject == self) {
      [mainMenu removeItemAtIndex:i];
    }
  }
}

/**
 * Returns the index in the application's mainMenu where Flutter menu items should be inserted.
 */
- (NSInteger)menuInsertionIndex {
  NSMenu *mainMenu = NSApp.mainMenu;
  NSInteger index = self.insertAfterMenuItem ? [mainMenu indexOfItem:self.insertAfterMenuItem] : -1;
  // If there's no (valid) insert-after, insert after the application menu at index zero.
  if (index == -1) {
    index = 0;
  }
  return index + 1;
}

/**
 * Removes an Flutter menu items that were previously added, then builds and adds new top-level menu
 * items constructed from |representation|.
 */
- (void)rebuildFlutterMenusFromRepresentation:(NSArray<NSDictionary *> *)representation {
  [self removeFlutterMenus];
  NSMenu *mainMenu = NSApp.mainMenu;
  NSInteger insertionIndex = [self menuInsertionIndex];
  for (NSDictionary *item in representation.reverseObjectEnumerator) {
    NSMenuItem *menuItem = [self menuItemFromJSONRepresentation:item];
    menuItem.representedObject = self;
    [mainMenu insertItem:menuItem atIndex:insertionIndex];
  }
}

/**
 * Constructs and returns an NSMenuItem corresponding to the item in |representation|, including
 * recursively creating children if it has a submenu.
 */
- (NSMenuItem *)menuItemFromJSONRepresentation:(NSDictionary *)representation {
  if (representation[@(plugins_menubar::kDividerKey)]) {
    return [NSMenuItem separatorItem];
  } else {
    NSString *title = representation[@(plugins_menubar::kLabelKey)];
    NSNumber *boxedID = representation[@(plugins_menubar::kIdKey)];
    NSMenuItem *item = [[NSMenuItem alloc]
        initWithTitle:title
               action:(boxedID ? @selector(flutterMenuItemSelected:) : NULL)keyEquivalent:@""];
    if (boxedID) {
      item.tag = boxedID.intValue;
      item.target = self;
    }
    NSNumber *enabled = representation[@(plugins_menubar::kEnabledKey)];
    if (enabled) {
      item.enabled = enabled.boolValue;
    }
    NSArray *children = representation[@(plugins_menubar::kChildrenKey)];
    if (children) {
      NSMenu *submenu = [[NSMenu alloc] initWithTitle:title];
      submenu.autoenablesItems = NO;
      for (NSDictionary *child in children) {
        [submenu addItem:[self menuItemFromJSONRepresentation:child]];
      }
      item.submenu = submenu;
    }
    return item;
  }
}

/**
 * Invokes kMenuItemSelectedCallbackMethod with the senders ID.
 *
 * Used as the callback for all Flutter-created menu items that have IDs.
 */
- (void)flutterMenuItemSelected:(id)sender {
  NSMenuItem *item = sender;
  [_channel invokeMethod:@(plugins_menubar::kMenuItemSelectedCallbackMethod) arguments:@(item.tag)];
}

#pragma FLEPlugin implementation

+ (void)registerWithRegistrar:(id<FLEPluginRegistrar>)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@(plugins_menubar::kChannelName)
                                  binaryMessenger:registrar.messenger
                                            codec:[FlutterJSONMethodCodec sharedInstance]];
  FLEMenubarPlugin *instance = [[FLEMenubarPlugin alloc] initWithChannel:channel];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([call.method isEqualToString:@(plugins_menubar::kMenuSetMethod)]) {
    NSArray *menus = call.arguments;
    [self rebuildFlutterMenusFromRepresentation:menus];
    result(nil);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end

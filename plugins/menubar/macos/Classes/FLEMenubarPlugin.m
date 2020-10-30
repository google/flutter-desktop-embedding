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

// See menu_channel.dart for documentation.
static NSString *const kChannelName = @"flutter/menubar";
static NSString *const kMenuSetMethod = @"Menubar.SetMenu";
static NSString *const kMenuItemSelectedCallbackMethod = @"Menubar.SelectedCallback";
static NSString *const kIdKey = @"id";
static NSString *const kLabelKey = @"label";
static NSString *const kShortcutKeyEquivalent = @"keyEquivalent";
static NSString *const kShortcutSpecialKey = @"specialKey";
static NSString *const kShortcutKeyModifiers = @"keyModifiers";
static NSString *const kEnabledKey = @"enabled";
static NSString *const kChildrenKey = @"children";
static NSString *const kDividerKey = @"isDivider";

static const int kFlutterShortcutModifierMeta = 1 << 0;
static const int kFlutterShortcutModifierShift = 1 << 1;
static const int kFlutterShortcutModifierAlt = 1 << 2;
static const int kFlutterShortcutModifierControl = 1 << 3;

// Returns the string used by NSMenuItem for the given special key.
// See _shortcutSpecialKeyValues in menu_channel.dart for values.
static NSString *KeyEquivalentCharacterForSpecialKey(int specialKey) {
  unichar character;
  switch (specialKey) {
    case 1:
      character = NSF1FunctionKey;
      break;
    case 2:
      character = NSF2FunctionKey;
      break;
    case 3:
      character = NSF3FunctionKey;
      break;
    case 4:
      character = NSF4FunctionKey;
      break;
    case 5:
      character = NSF5FunctionKey;
      break;
    case 6:
      character = NSF6FunctionKey;
      break;
    case 7:
      character = NSF7FunctionKey;
      break;
    case 8:
      character = NSF8FunctionKey;
      break;
    case 9:
      character = NSF9FunctionKey;
      break;
    case 10:
      character = NSF10FunctionKey;
      break;
    case 11:
      character = NSF11FunctionKey;
      break;
    case 12:
      character = NSF12FunctionKey;
      break;
    case 13:
      character = NSBackspaceCharacter;
      break;
    case 14:
      character = NSDeleteCharacter;
      break;
    default:
      return nil;
  }
  return [NSString stringWithCharacters:&character length:1];
}

// Returns the NSEventModifierFlags of |modifiers|, a value from kShortcutKeyModifiers.
static NSEventModifierFlags KeyEquivalentModifierMaskForModifiers(NSNumber *modifiers) {
  int flutterModifierFlags = modifiers.intValue;
  NSEventModifierFlags flags = 0;
  if (flutterModifierFlags & kFlutterShortcutModifierMeta) flags |= NSEventModifierFlagCommand;
  if (flutterModifierFlags & kFlutterShortcutModifierShift) flags |= NSEventModifierFlagShift;
  if (flutterModifierFlags & kFlutterShortcutModifierAlt) flags |= NSEventModifierFlagOption;
  if (flutterModifierFlags & kFlutterShortcutModifierControl) flags |= NSEventModifierFlagControl;
  return flags;
}

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
    NSMenuItem *menuItem = [self menuItemFromFlutterRepresentation:item];
    menuItem.representedObject = self;
    [mainMenu insertItem:menuItem atIndex:insertionIndex];
  }
}

/**
 * Constructs and returns an NSMenuItem corresponding to the item in |representation|, including
 * recursively creating children if it has a submenu.
 */
- (NSMenuItem *)menuItemFromFlutterRepresentation:(NSDictionary *)representation {
  if (representation[kDividerKey]) {
    return [NSMenuItem separatorItem];
  } else {
    NSString *title = representation[kLabelKey];
    NSNumber *boxedID = representation[kIdKey];

    NSString *keyEquivalent = nil;
    if (representation[kShortcutKeyEquivalent]) {
      keyEquivalent = representation[kShortcutKeyEquivalent];
    } else if (representation[kShortcutSpecialKey]) {
      int specialKey = ((NSNumber *)representation[kShortcutSpecialKey]).intValue;
      keyEquivalent = KeyEquivalentCharacterForSpecialKey(specialKey);
    }

    SEL action = (boxedID ? @selector(flutterMenuItemSelected:) : NULL);
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title
                                                  action:action
                                           keyEquivalent:(keyEquivalent ?: @"")];
    if (keyEquivalent) {
      item.keyEquivalentModifierMask =
          KeyEquivalentModifierMaskForModifiers(representation[kShortcutKeyModifiers]);
    }
    if (boxedID) {
      item.tag = boxedID.intValue;
      item.target = self;
    }
    NSNumber *enabled = representation[kEnabledKey];
    if (enabled) {
      item.enabled = enabled.boolValue;
    }

    NSArray *children = representation[kChildrenKey];
    if (children) {
      NSMenu *submenu = [[NSMenu alloc] initWithTitle:title];
      submenu.autoenablesItems = NO;
      for (NSDictionary *child in children) {
        [submenu addItem:[self menuItemFromFlutterRepresentation:child]];
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
  [_channel invokeMethod:kMenuItemSelectedCallbackMethod arguments:@(item.tag)];
}

#pragma FlutterPlugin implementation

+ (void)registerWithRegistrar:(id<FlutterPluginRegistrar>)registrar {
  FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:kChannelName
                                                              binaryMessenger:registrar.messenger];
  FLEMenubarPlugin *instance = [[FLEMenubarPlugin alloc] initWithChannel:channel];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([call.method isEqualToString:kMenuSetMethod]) {
    NSArray *menus = call.arguments;
    [self rebuildFlutterMenusFromRepresentation:menus];
    result(nil);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end

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
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'menu_item.dart';

/// Whether or not the menu item is a divider, as a boolean. If true, no other
/// The name of the plugin's platform channel.
const String _kMenuChannelName = 'flutter/menubar';

/// The method name to instruct the native plugin to set the menu.
//
/// The argument to this method will be an array of map representations
/// of menus that should be set as top-level menu items.
const String _kMenuSetMethod = 'Menubar.SetMenu';

/// The method name for the Dart-side callback called when a menu item is
/// selected.
//
/// The argument to this method must be the ID of the selected menu item, as
/// provided in the kIdKey field in the kMenuSetMethod call.
const String _kMenuItemSelectedCallbackMethod = 'Menubar.SelectedCallback';

// Keys for the map representations of menus sent to kMenuSetMethod.

/// The ID of the menu item, as an integer. If present, this indicates that the
/// menu item should trigger a kMenuItemSelectedCallbackMethod call when
/// selected.
const String _kIdKey = 'id';

/// The label that should be displayed for the menu, as a string.
const String _kLabelKey = 'label';

/// The string corresponding to the shortcut key equivalent without modifiers.
///
/// When menu support moves into Flutter itself, this will likely use keyId.
/// That's not useable for this plugin-based prototype however, since keyId is
/// not stable.
const String _kShortcutKeyEquivalent = 'keyEquivalent';

/// An alternative to _kShortcutKeyEquivalent for keys that have no string
/// equivalent. Only this or _kShortcutKeyEquivalent should be specified.
///
/// This is a partial workaround for the lack of keyId discussed above, to
/// handle common shortcut keys that _kShortcutKeyEquivalent can't represent.
///
/// See _ShortcutSpecialKeys for possible values.
const String _kShortcutSpecialKey = 'specialKey';

/// The modifier flags to apply to the shortcut key.
///
/// The value is an int representing a flag set; see below for possible values.
const String _kShortcutKeyModifiers = 'keyModifiers';

/// Whether or not the menu item should be enabled, as a boolean. If not present
/// the defualt is to enabled the item.
const String _kEnabledKey = 'enabled';

/// Menu items that should be shown as a submenu of this item, as an array.
const String _kChildrenKey = 'children';

/// Whether or not the menu item is a divider, as a boolean. If true, no other
/// keys will be present.
const String _kDividerKey = 'isDivider';

// Values for _kShortcutKeyModifiers.
const int _shortcutModifierMeta = 1 << 0;
const int _shortcutModifierShift = 1 << 1;
const int _shortcutModifierAlt = 1 << 2;
const int _shortcutModifierControl = 1 << 3;

/// Values for _kShortcutSpecialKey.
final _shortcutSpecialKeyValues = <LogicalKeyboardKey, int>{
  LogicalKeyboardKey.f1: 1,
  LogicalKeyboardKey.f2: 2,
  LogicalKeyboardKey.f3: 3,
  LogicalKeyboardKey.f4: 4,
  LogicalKeyboardKey.f5: 5,
  LogicalKeyboardKey.f6: 6,
  LogicalKeyboardKey.f7: 7,
  LogicalKeyboardKey.f8: 8,
  LogicalKeyboardKey.f9: 9,
  LogicalKeyboardKey.f10: 10,
  LogicalKeyboardKey.f11: 11,
  LogicalKeyboardKey.f12: 12,
  LogicalKeyboardKey.backspace: 13,
  LogicalKeyboardKey.delete: 14,
};

/// A singleton object that handles the interaction with the menu bar platform
/// channel.
class MenuChannel {
  /// Private constructor.
  MenuChannel._() {
    _platformChannel.setMethodCallHandler(_callbackHandler);
  }

  final MethodChannel _platformChannel = const MethodChannel(_kMenuChannelName);

  /// Map from unique identifiers assigned by this class to the callbacks for
  /// those menu items.
  final Map<int, MenuSelectedCallback> _selectionCallbacks = {};

  /// The ID to use the next time a menu item needs an ID assigned.
  int _nextMenuItemId = 1;

  /// Whether or not a call to [_kMenuSetMethod] is outstanding.
  ///
  /// This is used to drop any menu callbacks that aren't received until
  /// after a new call to setMenu, so that clients don't received unexpected
  /// stale callbacks.
  bool _updateInProgress = false;

  /// The static instance of the menu channel.
  static final MenuChannel instance = new MenuChannel._();

  /// Sets the native application menu to [menus].
  ///
  /// How exactly this is handled is subject to platform interpretation.
  /// For instance, special menus that are handled entirely on the native
  /// side might be added to the provided menus.
  Future<Null> setMenu(List<Submenu> menus) async {
    try {
      _updateInProgress = true;
      await _platformChannel.invokeMethod(
          _kMenuSetMethod, _channelRepresentationForMenus(menus));
      _updateInProgress = false;
    } on PlatformException catch (e) {
      print('Platform exception setting menu: ${e.message}');
    }
  }

  /// Converts [menus] to a representation that can be sent in the arguments to
  /// [_kMenuSetMethod].
  ///
  /// As a side-effect, repopulates _selectionCallbacks with a mapping from
  /// the IDs assigned to any menu item with a selection handler to the
  /// callback that should be triggered.
  List<dynamic> _channelRepresentationForMenus(List<Submenu> menus) {
    _selectionCallbacks.clear();
    _nextMenuItemId = 1;

    return menus.map(_channelRepresentationForMenuItem).toList();
  }

  /// Returns a representation of [item] suitable for passing over the
  /// platform channel to the native plugin.
  Map<String, dynamic> _channelRepresentationForMenuItem(
      AbstractMenuItem item) {
    final representation = <String, dynamic>{};
    if (item is MenuDivider) {
      representation[_kDividerKey] = true;
    } else {
      representation[_kLabelKey] = item.label;
      if (item is Submenu) {
        representation[_kChildrenKey] =
            _channelRepresentationForMenu(item.children);
      } else if (item is MenuItem) {
        final handler = item.onClicked;
        if (handler != null) {
          representation[_kIdKey] = _storeMenuCallback(handler);
        }
        if (!item.enabled) {
          representation[_kEnabledKey] = false;
        }
        final shortcut = item.shortcut;
        if (shortcut != null) {
          _addShortcutToRepresentation(shortcut, representation);
        }
      } else {
        throw ArgumentError(
            'Unknown AbstractMenuItem type: $item (${item.runtimeType})');
      }
    }
    return representation;
  }

  /// Returns the representation of [menu] suitable for passing over the
  /// platform channel to the native plugin.
  List<dynamic> _channelRepresentationForMenu(List<AbstractMenuItem> menu) {
    final menuItemRepresentations = [];
    // Dividers are only allowed after non-divider items (see ApplicationMenu).
    var skipNextDivider = true;
    for (final menuItem in menu) {
      final isDivider = menuItem is MenuDivider;
      if (isDivider && skipNextDivider) {
        continue;
      }
      skipNextDivider = isDivider;
      menuItemRepresentations.add(_channelRepresentationForMenuItem(menuItem));
    }
    // If the last item is a divider, remove it (see ApplicationMenu).
    if (skipNextDivider && menuItemRepresentations.isNotEmpty) {
      menuItemRepresentations.removeLast();
    }
    return menuItemRepresentations;
  }

  /// Populates [channelRepresentation] with the platform channel representation
  /// of [shortcut], using [_kShortcutKeyEquivalent], [_kShortcutSpecialKey],
  /// and/or [_kShortcutKeyModifiers].
  void _addShortcutToRepresentation(
      LogicalKeySet shortcut, Map<String, dynamic> channelRepresentation) {
    var hasNonModifierKey = false;
    var modifiers = 0;
    for (final key in shortcut.keys) {
      if (key == LogicalKeyboardKey.meta) {
        modifiers |= _shortcutModifierMeta;
      } else if (key == LogicalKeyboardKey.shift) {
        modifiers |= _shortcutModifierShift;
      } else if (key == LogicalKeyboardKey.alt) {
        modifiers |= _shortcutModifierAlt;
      } else if (key == LogicalKeyboardKey.control) {
        modifiers |= _shortcutModifierControl;
      } else {
        if (hasNonModifierKey) {
          throw ArgumentError('Invalid menu item shortcut: $shortcut\n'
              'Menu items must have exactly one non-modifier key.');
        }

        if (key.keyLabel.isNotEmpty) {
          channelRepresentation[_kShortcutKeyEquivalent] = key.keyLabel.toLowerCase();
        } else {
          final specialKey = _shortcutSpecialKeyValues[key];
          if (specialKey == null) {
            throw ArgumentError('Unsupported menu shortcut key: $key\n'
                'Please add this key to the special key mapping.');
          }
          channelRepresentation[_kShortcutSpecialKey] = specialKey;
        }
        hasNonModifierKey = true;
      }
    }

    if (!hasNonModifierKey) {
      throw ArgumentError('Invalid menu item shortcut: $shortcut\n'
          'Menu items must have exactly one non-modifier key.');
    }
    channelRepresentation[_kShortcutKeyModifiers] = modifiers;
  }

  /// Stores [callback] for use plugin callback handling, returning the ID
  /// under which it was stored.
  ///
  /// The returned ID should be attached to the menu so that the native plugin
  /// can identify the menu item selected in the callback.
  int _storeMenuCallback(MenuSelectedCallback callback) {
    final id = _nextMenuItemId++;
    _selectionCallbacks[id] = callback;
    return id;
  }

  /// Mediates between the platform channel callback and the client callback.
  Future<Null> _callbackHandler(MethodCall methodCall) async {
    if (methodCall.method == _kMenuItemSelectedCallbackMethod) {
      if (_updateInProgress) {
        // Drop stale callbacks.
        // TODO: Evaluate whether this works in practice, or if races are
        // regular occurences that clients will need to be prepared to
        // handle (in which case a more complex ID system will be needed).
        print('Warning: Menu selection callback received during menu update.');
        return;
      }
      final int menuItemId = methodCall.arguments;
      final callback = _selectionCallbacks[menuItemId];
      if (callback == null) {
        throw Exception('Unknown menu item ID $menuItemId');
      }
      callback();
    }
  }
}

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

import 'menu_item.dart';

// Plugin channel constants. See common/channel_constants.h for details.
const String _kMenuChannelName = 'flutter/menubar';
const String _kMenuSetMethod = 'Menubar.SetMenu';
const String _kMenuItemSelectedCallbackMethod = 'Menubar.SelectedCallback';
const String _kIdKey = 'id';
const String _kLabelKey = 'label';
const String _kEnabledKey = 'enabled';
const String _kChildrenKey = 'children';
const String _kDividerKey = 'isDivider';

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
  bool _updateInProgress;

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
        if (item.onClicked != null) {
          representation[_kIdKey] = _storeMenuCallback(item.onClicked);
        }
        if (!item.enabled) {
          representation[_kEnabledKey] = false;
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
      try {
        if (_updateInProgress) {
          // Drop stale callbacks.
          // TODO: Evaluate whether this works in practice, or if races are
          // regular occurences that clients will need to be prepared to
          // handle (in which case a more complex ID system will be needed).
          print(
              'Warning: Menu selection callback received during menu update.');
          return;
        }
        final int menuItemId = methodCall.arguments;
        _selectionCallbacks[menuItemId]();
      } on Exception catch (e, s) {
        print('Exception in callback handler: $e\n$s');
      }
    }
  }
}

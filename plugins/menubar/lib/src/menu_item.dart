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
import 'package:flutter/widgets.dart';

/// A callback provided to [MenuItem] to handle menu selection.
typedef MenuSelectedCallback = void Function();

/// The base type for an individual menu item that can be shown in a menu.
abstract class AbstractMenuItem {
  /// Creates a new menu item with the give label.
  const AbstractMenuItem(this.label);

  /// The displayed label for the menu item.
  final String label;
}

/// A standard menu item, with no submenus.
class MenuItem extends AbstractMenuItem {
  /// Creates a new menu item with the given [label] and options.
  ///
  /// Note that onClicked should generally be set unless [enabled] is false,
  /// or the menu item will be selectable but not do anything.
  const MenuItem({
    required String label,
    this.shortcut,
    this.enabled = true,
    this.onClicked,
  }) : super(label);

  /// The callback to call whenever the menu item is selected.
  final MenuSelectedCallback? onClicked;

  /// Whether or not the menu item is enabled.
  final bool enabled;

  /// The shortcut/accelerator for the menu item, if any.
  ///
  /// Note: Currently modifiers have only Left or Right variants, so must be
  /// specified with one of those. The actual left/right distinction will be
  /// ignored. This part of the API is likely to change in the future.
  ///
  /// Example: a Save menu item would likely use:
  ///   LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS)
  final LogicalKeySet? shortcut;
}

/// A menu item continaing a submenu.
///
/// The item itself can't be selected, it just displays the submenu.
class Submenu extends AbstractMenuItem {
  /// Creates a new submenu with the given [label] and [children].
  const Submenu({required String label, required this.children}) : super(label);

  /// The menu items contained in the submenu.
  final List<AbstractMenuItem> children;
}

/// A menu item that serves as a divider, generally drawn as a line.
class MenuDivider extends AbstractMenuItem {
  /// Creates a new divider item.
  const MenuDivider() : super('');
}

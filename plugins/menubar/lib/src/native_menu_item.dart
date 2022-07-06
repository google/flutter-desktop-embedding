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

/// The base type for an individual menu item that can be shown in a menu.
abstract class AbstractNativeMenuItem {
  /// Creates a new menu item with the give label.
  const AbstractNativeMenuItem(this.label);

  /// The displayed label for the menu item.
  final String label;
}

/// A standard menu item, with no submenus.
class NativeMenuItem extends AbstractNativeMenuItem {
  /// Creates a new menu item with the given [label] and options.
  const NativeMenuItem({
    required String label,
    this.shortcut,
    this.onSelected,
  }) : super(label);

  /// The callback to call whenever the menu item is selected.
  ///
  /// If null, the menu item is disabled.
  final VoidCallback? onSelected;

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
class NativeSubmenu extends AbstractNativeMenuItem {
  /// Creates a new submenu with the given [label] and [children].
  const NativeSubmenu({required String label, required this.children})
      : super(label);

  /// The menu items contained in the submenu.
  final List<AbstractNativeMenuItem> children;
}

/// A menu item that serves as a divider, generally drawn as a line.
class NativeMenuDivider extends AbstractNativeMenuItem {
  /// Creates a new divider item.
  const NativeMenuDivider() : super('');
}

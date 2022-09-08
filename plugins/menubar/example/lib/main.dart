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

/// Flutter code sample for [PlatformMenuBar].

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const SampleApp());

enum MenuSelection {
  about,
  showMessage,
}

class SampleApp extends StatelessWidget {
  const SampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: MyMenuBarApp()),
    );
  }
}

class MyMenuBarApp extends StatefulWidget {
  const MyMenuBarApp({Key? key}) : super(key: key);

  @override
  State<MyMenuBarApp> createState() => _MyMenuBarAppState();
}

class _MyMenuBarAppState extends State<MyMenuBarApp> {
  String _message = 'Hello';
  bool _showMessage = false;

  void _handleMenuSelection(MenuSelection value) {
    switch (value) {
      case MenuSelection.about:
        showAboutDialog(
          context: context,
          applicationName: 'MenuBar Sample',
          applicationVersion: '1.0.0',
        );
        break;
      case MenuSelection.showMessage:
        setState(() {
          _showMessage = !_showMessage;
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // This builds a menu hierarchy that looks like this:
    // Flutter API Sample
    //  ├ About
    //  ├ ────────  (group divider)
    //  ├ Hide/Show Message
    //  ├ Messages
    //  │  ├ I am not throwing away my shot.
    //  │  └ There's a million things I haven't done, but just you wait.
    //  └ Quit
    return PlatformMenuBar(
      menus: <PlatformMenuItem>[
        PlatformMenu(
          label: 'Flutter API Sample',
          menus: <PlatformMenuItem>[
            PlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                PlatformMenuItem(
                  label: 'About',
                  onSelected: () {
                    _handleMenuSelection(MenuSelection.about);
                  },
                )
              ],
            ),
            PlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                PlatformMenuItem(
                  onSelected: () {
                    _handleMenuSelection(MenuSelection.showMessage);
                  },
                  shortcut: const CharacterActivator('m'),
                  label: _showMessage ? 'Hide Message' : 'Show Message',
                ),
                PlatformMenu(
                  label: 'Messages',
                  menus: <PlatformMenuItem>[
                    PlatformMenuItem(
                      label: 'I am not throwing away my shot.',
                      shortcut: const SingleActivator(LogicalKeyboardKey.digit1, meta: true),
                      onSelected: () {
                        setState(() {
                          _message = 'I am not throwing away my shot.';
                        });
                      },
                    ),
                    PlatformMenuItem(
                      label: "There's a million things I haven't done, but just you wait.",
                      shortcut: const SingleActivator(LogicalKeyboardKey.digit2, meta: true),
                      onSelected: () {
                        setState(() {
                          _message = "There's a million things I haven't done, but just you wait.";
                        });
                      },
                    ),
                  ],
                )
              ],
            ),
            if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.quit))
              const PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit),
          ],
        ),
      ],
      child: Center(
        child: Text(_showMessage
            ? _message
            : 'This space intentionally left blank.\n'
            'Show a message here using the menu.'),
      ),
    );
  }
}

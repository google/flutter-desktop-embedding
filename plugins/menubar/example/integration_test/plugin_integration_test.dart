// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://docs.flutter.dev/cookbook/testing/integration/introduction

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:menubar/menubar.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sanity check', (tester) async {
    expect(
        setApplicationMenu([
          NativeSubmenu(label: 'Test', children: [
            NativeMenuItem(
                label: '1',
                shortcut: LogicalKeySet(
                    LogicalKeyboardKey.meta, LogicalKeyboardKey.keyA),
                onSelected: () {}),
            const NativeMenuDivider(),
            NativeSubmenu(label: 'Presets', children: [
              NativeMenuItem(
                  label: '2',
                  shortcut: LogicalKeySet(LogicalKeyboardKey.meta,
                      LogicalKeyboardKey.shift, LogicalKeyboardKey.keyB),
                  onSelected: null),
            ])
          ]),
        ]),
        completes);
  });
}

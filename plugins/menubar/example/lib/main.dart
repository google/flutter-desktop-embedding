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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:menubar/menubar.dart';

void main() {
  runApp(const MyApp());
}

/// Top level widget for the application.
class MyApp extends StatefulWidget {
  /// Constructs a new app with the given [key].
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _AppState();
}

class _AppState extends State<MyApp> {
  Color _primaryColor = Colors.blue;
  int _counter = 0;

  static _AppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_AppState>();

  /// Sets the primary color of the app.
  void setPrimaryColor(Color color) {
    setState(() {
      _primaryColor = color;
    });
  }

  void incrementCounter() {
    _setCounter(_counter + 1);
  }

  void _decrementCounter() {
    _setCounter(_counter - 1);
  }

  void _setCounter(int value) {
    setState(() {
      _counter = value;
    });
  }

  /// Rebuilds the native menu bar based on the current state.
  void updateMenubar() {
    setApplicationMenu([
      NativeSubmenu(label: 'Color', children: [
        NativeMenuItem(
            label: 'Reset',
            shortcut: LogicalKeySet(
                LogicalKeyboardKey.meta, LogicalKeyboardKey.backspace),
            onSelected: _primaryColor == Colors.blue
                ? null
                : () {
                    setPrimaryColor(Colors.blue);
                  }),
        const NativeMenuDivider(),
        NativeSubmenu(label: 'Presets', children: [
          NativeMenuItem(
              label: 'Red',
              shortcut: LogicalKeySet(LogicalKeyboardKey.meta,
                  LogicalKeyboardKey.shift, LogicalKeyboardKey.keyR),
              onSelected: _primaryColor == Colors.red
                  ? null
                  : () {
                      setPrimaryColor(Colors.red);
                    }),
          NativeMenuItem(
              label: 'Green',
              shortcut: LogicalKeySet(LogicalKeyboardKey.meta,
                  LogicalKeyboardKey.alt, LogicalKeyboardKey.keyG),
              onSelected: _primaryColor == Colors.green
                  ? null
                  : () {
                      setPrimaryColor(Colors.green);
                    }),
          NativeMenuItem(
              label: 'Purple',
              shortcut: LogicalKeySet(LogicalKeyboardKey.meta,
                  LogicalKeyboardKey.control, LogicalKeyboardKey.keyP),
              onSelected: _primaryColor == Colors.deepPurple
                  ? null
                  : () {
                      setPrimaryColor(Colors.deepPurple);
                    }),
        ])
      ]),
      NativeSubmenu(label: 'Counter', children: [
        NativeMenuItem(
            label: 'Reset',
            shortcut: LogicalKeySet(
                LogicalKeyboardKey.meta, LogicalKeyboardKey.digit0),
            onSelected: _counter == 0
                ? null
                : () {
                    _setCounter(0);
                  }),
        const NativeMenuDivider(),
        NativeMenuItem(
            label: 'Increment',
            shortcut: LogicalKeySet(LogicalKeyboardKey.f2),
            onSelected: incrementCounter),
        NativeMenuItem(
            label: 'Decrement',
            shortcut: LogicalKeySet(LogicalKeyboardKey.f1),
            onSelected: _counter == 0 ? null : _decrementCounter),
      ]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // Any time the state changes, the menu needs to be rebuilt.
    updateMenubar();

    final theme = ThemeData();
    return MaterialApp(
      title: 'Flutter Demo',
      theme: theme.copyWith(
        colorScheme: theme.colorScheme
            .copyWith(primary: _primaryColor, secondary: _primaryColor),
      ),
      darkTheme: ThemeData.dark(),
      home: _MyHomePage(title: 'Flutter Demo Home Page', counter: _counter),
    );
  }
}

class _MyHomePage extends StatelessWidget {
  const _MyHomePage({required this.title, this.counter = 0});

  final String title;
  final int counter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: LayoutBuilder(
        builder: (context, viewportConstraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: viewportConstraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'You have pushed the button this many times:',
                    ),
                    Text(
                      '$counter',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _AppState.of(context)!.incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

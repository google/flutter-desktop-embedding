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
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';

import 'package:color_panel/color_panel.dart';
import 'package:file_chooser/file_chooser.dart' as file_chooser;
import 'package:menubar/menubar.dart';

void main() {
  // Desktop platforms are not recognized as valid targets by
  // Flutter; force a specific target to prevent exceptions.
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  runApp(new MyApp());
}

/// Top level widget for the example application.
class MyApp extends StatefulWidget {
  /// Constructs a new app with the given [key].
  const MyApp({Key key}) : super(key: key);

  @override
  _AppState createState() => new _AppState();
}

class _AppState extends State<MyApp> {
  Color _primaryColor = Colors.blue;
  int _counter = 0;

  static _AppState of(BuildContext context) =>
      context.ancestorStateOfType(const TypeMatcher<_AppState>());

  /// Sets the primary color of the example app.
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
    // Currently the menubar plugin is only implemented on macOS.
    if (!Platform.isMacOS) {
      return;
    }
    setApplicationMenu([
      Submenu(label: 'Color', children: [
        MenuItem(
            label: 'Reset',
            enabled: _primaryColor != Colors.blue,
            onClicked: () {
              setPrimaryColor(Colors.blue);
            }),
        MenuDivider(),
        Submenu(label: 'Presets', children: [
          MenuItem(
              label: 'Red',
              enabled: _primaryColor != Colors.red,
              onClicked: () {
                setPrimaryColor(Colors.red);
              }),
          MenuItem(
              label: 'Green',
              enabled: _primaryColor != Colors.green,
              onClicked: () {
                setPrimaryColor(Colors.green);
              }),
          MenuItem(
              label: 'Purple',
              enabled: _primaryColor != Colors.deepPurple,
              onClicked: () {
                setPrimaryColor(Colors.deepPurple);
              }),
        ])
      ]),
      Submenu(label: 'Counter', children: [
        MenuItem(
            label: 'Reset',
            enabled: _counter != 0,
            onClicked: () {
              _setCounter(0);
            }),
        MenuDivider(),
        MenuItem(label: 'Increment', onClicked: incrementCounter),
        MenuItem(
            label: 'Decrement',
            enabled: _counter > 0,
            onClicked: _decrementCounter),
      ]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // Any time the state changes, the menu needs to be rebuilt.
    updateMenubar();

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: _primaryColor,
        accentColor: _primaryColor,
        // Specify a font to reduce potential issues with the
        // example behaving differently on different platforms.
        fontFamily: 'Roboto',
      ),
      home: _MyHomePage(title: 'Flutter Demo Home Page', counter: _counter),
    );
  }
}

class _MyHomePage extends StatelessWidget {
  final String title;
  final int counter;

  const _MyHomePage({this.title, this.counter = 0});

  void _changePrimaryThemeColor(BuildContext context) {
    final colorPanel = ColorPanel.instance;
    if (!colorPanel.showing) {
      colorPanel.show((color) {
        _AppState.of(context).setPrimaryColor(color);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          new IconButton(
            icon: new Icon(Icons.color_lens),
            tooltip: 'Change theme color',
            onPressed: () {
              _changePrimaryThemeColor(context);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            new Text(
              '$counter',
              style: Theme.of(context).textTheme.display1,
            ),
            TextInputTestWidget(),
            FileChooserTestWidget(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _AppState.of(context).incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}

/// A widget containing controls to test the file chooser plugin.
class FileChooserTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ButtonBar(
      alignment: MainAxisAlignment.center,
      children: <Widget>[
        new FlatButton(
          child: const Text('SAVE'),
          onPressed: () {
            file_chooser.showSavePanel((result, paths) {
              Scaffold.of(context).showSnackBar(SnackBar(
                    content: Text(_resultTextForFileChooserOperation(
                        _FileChooserType.save, result, paths)),
                  ));
            }, suggestedFileName: 'save_test.txt');
          },
        ),
        new FlatButton(
          child: const Text('OPEN'),
          onPressed: () {
            file_chooser.showOpenPanel((result, paths) {
              Scaffold.of(context).showSnackBar(SnackBar(
                    content: Text(_resultTextForFileChooserOperation(
                        _FileChooserType.open, result, paths)),
                  ));
            }, allowsMultipleSelection: true);
          },
        ),
      ],
    );
  }
}

/// A widget containing controls to test text input.
class TextInputTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const <Widget>[
        SampleTextField(),
        SampleTextField(),
      ],
    );
  }
}

/// A text field with styling suitable for including in a TextInputTestWidget.
class SampleTextField extends StatelessWidget {
  /// Creates a new sample text field.
  const SampleTextField();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200.0,
      padding: const EdgeInsets.all(10.0),
      child: TextField(
        decoration: InputDecoration(border: OutlineInputBorder()),
      ),
    );
  }
}

/// Possible file chooser operation types.
enum _FileChooserType { save, open }

/// Returns display text reflecting the result of a file chooser operation.
String _resultTextForFileChooserOperation(
    _FileChooserType type, file_chooser.FileChooserResult result,
    [List<String> paths]) {
  if (result == file_chooser.FileChooserResult.cancel) {
    return '${type == _FileChooserType.open ? 'Open' : 'Save'} cancelled';
  }
  final statusText = type == _FileChooserType.open ? 'Opened' : 'Saved';
  return '$statusText: ${paths.join('\n')}';
}

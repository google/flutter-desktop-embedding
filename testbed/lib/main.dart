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
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:file_chooser/file_chooser.dart';
import 'package:menubar/menubar.dart';
import 'package:window_size/window_size.dart' as window_size;

import 'keyboard_test_page.dart';

void main() {
  // Try to resize and reposition the window to be half the width and height
  // of its screen, centered horizontally and shifted up from center.
  WidgetsFlutterBinding.ensureInitialized();
  window_size.getWindowInfo().then((window) {
    if (window.screen != null) {
      final screenFrame = window.screen.visibleFrame;
      final width = math.max((screenFrame.width / 2).roundToDouble(), 800.0);
      final height = math.max((screenFrame.height / 2).roundToDouble(), 600.0);
      final left = ((screenFrame.width - width) / 2).roundToDouble();
      final top = ((screenFrame.height - height) / 3).roundToDouble();
      final frame = Rect.fromLTWH(left, top, width, height);
      window_size.setWindowFrame(frame);
      window_size.setWindowMinSize(Size(0.8 * width, 0.8 * height));
      window_size.setWindowMaxSize(Size(1.5 * width, 1.5 * height));
      window_size
          .setWindowTitle('Flutter Testbed on ${Platform.operatingSystem}');
    }
  });

  runApp(new MyApp());
}

/// Top level widget for the application.
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
      Submenu(label: 'Color', children: [
        MenuItem(
            label: 'Reset',
            enabled: _primaryColor != Colors.blue,
            shortcut: LogicalKeySet(
                LogicalKeyboardKey.meta, LogicalKeyboardKey.backspace),
            onClicked: () {
              setPrimaryColor(Colors.blue);
            }),
        MenuDivider(),
        Submenu(label: 'Presets', children: [
          MenuItem(
              label: 'Red',
              enabled: _primaryColor != Colors.red,
              shortcut: LogicalKeySet(LogicalKeyboardKey.meta,
                  LogicalKeyboardKey.shift, LogicalKeyboardKey.keyR),
              onClicked: () {
                setPrimaryColor(Colors.red);
              }),
          MenuItem(
              label: 'Green',
              enabled: _primaryColor != Colors.green,
              shortcut: LogicalKeySet(LogicalKeyboardKey.meta,
                  LogicalKeyboardKey.alt, LogicalKeyboardKey.keyG),
              onClicked: () {
                setPrimaryColor(Colors.green);
              }),
          MenuItem(
              label: 'Purple',
              enabled: _primaryColor != Colors.deepPurple,
              shortcut: LogicalKeySet(LogicalKeyboardKey.meta,
                  LogicalKeyboardKey.control, LogicalKeyboardKey.keyP),
              onClicked: () {
                setPrimaryColor(Colors.deepPurple);
              }),
        ])
      ]),
      Submenu(label: 'Counter', children: [
        MenuItem(
            label: 'Reset',
            enabled: _counter != 0,
            shortcut: LogicalKeySet(
                LogicalKeyboardKey.meta, LogicalKeyboardKey.digit0),
            onClicked: () {
              _setCounter(0);
            }),
        MenuDivider(),
        MenuItem(
            label: 'Increment',
            shortcut: LogicalKeySet(LogicalKeyboardKey.f2),
            onClicked: incrementCounter),
        MenuItem(
            label: 'Decrement',
            enabled: _counter > 0,
            shortcut: LogicalKeySet(LogicalKeyboardKey.f1),
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
      ),
      darkTheme: ThemeData.dark(),
      home: _MyHomePage(title: 'Flutter Demo Home Page', counter: _counter),
    );
  }
}

class _MyHomePage extends StatelessWidget {
  const _MyHomePage({this.title, this.counter = 0});

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
                    new Text(
                      '$counter',
                      style: Theme.of(context).textTheme.headline4,
                    ),
                    TextInputTestWidget(),
                    FileChooserTestWidget(),
                    new RaisedButton(
                      child: new Text('Test raw keyboard events'),
                      onPressed: () {
                        Navigator.of(context).push(new MaterialPageRoute(
                            builder: (context) => KeyboardTestPage()));
                      },
                    ),
                    Container(
                      width: 380.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 1.0)),
                      child: Scrollbar(
                        child: ListView.builder(
                          padding: EdgeInsets.all(8.0),
                          itemExtent: 20.0,
                          itemCount: 50,
                          itemBuilder: (context, index) {
                            return Text('entry $index');
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
            showSavePanel(suggestedFileName: 'save_test.txt').then((result) {
              Scaffold.of(context).showSnackBar(SnackBar(
                content: Text(_resultTextForFileChooserOperation(
                    _FileChooserType.save, result)),
              ));
            });
          },
        ),
        new FlatButton(
          child: const Text('OPEN'),
          onPressed: () async {
            final result = await showOpenPanel(
                allowsMultipleSelection: true);
            Scaffold.of(context).showSnackBar(SnackBar(
                content: Text(_resultTextForFileChooserOperation(
                    _FileChooserType.open, result))));
          },
        ),
        new FlatButton(
          child: const Text('OPEN MEDIA'),
          onPressed: () async {
            final result =
                await showOpenPanel(allowedFileTypes: <FileTypeFilterGroup>[
              FileTypeFilterGroup(label: 'Images', fileExtensions: <String>[
                'bmp',
                'gif',
                'jpeg',
                'jpg',
                'png',
                'tiff',
                'webp',
              ]),
              FileTypeFilterGroup(label: 'Video', fileExtensions: <String>[
                'avi',
                'mov',
                'mpeg',
                'mpg',
                'webm',
              ]),
            ]);
            Scaffold.of(context).showSnackBar(SnackBar(
                content: Text(_resultTextForFileChooserOperation(
                    _FileChooserType.open, result))));
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
    _FileChooserType type, FileChooserResult result) {
  if (result.canceled) {
    return '${type == _FileChooserType.open ? 'Open' : 'Save'} cancelled';
  }
  final typeString = type == _FileChooserType.open ? 'opening' : 'saving';
  return 'Selected for $typeString: ${result.paths.join('\n')}';
}

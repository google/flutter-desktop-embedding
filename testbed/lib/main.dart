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

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:color_panel/color_panel.dart';
import 'package:example_flutter/keyboard_test_page.dart';
import 'package:example_plugin/example_plugin.dart' as example_plugin;
import 'package:file_chooser/file_chooser.dart' as file_chooser;
import 'package:menubar/menubar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:window_size/window_size.dart' as window_size;

// The shared_preferences key for the testbed's color.
const _prefKeyColor = 'color';

void main() {
  // Desktop platforms are not recognized as valid targets by
  // Flutter; force a specific target to prevent exceptions.
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;

  // Try to resize and reposition the window to be half the width and height
  // of its screen, centered horizontally and shifted up from center.
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isMacOS || Platform.isLinux) {
    window_size.getWindowInfo().then((window) {
      if (window.screen != null) {
        final screenFrame = window.screen.visibleFrame;
        final width = math.max((screenFrame.width / 2).roundToDouble(), 800.0);
        final height =
            math.max((screenFrame.height / 2).roundToDouble(), 600.0);
        final left = ((screenFrame.width - width) / 2).roundToDouble();
        final top = ((screenFrame.height - height) / 3).roundToDouble();
        final frame = Rect.fromLTWH(left, top, width, height);
        window_size.setWindowFrame(frame);
      }
    });
  }

  example_plugin.ExamplePlugin.platformVersion.then((versionInfo) {
    print('Example plugin returned $versionInfo');
  });

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
  _AppState() {
    if (Platform.isMacOS) {
      SharedPreferences.getInstance().then((prefs) {
        if (prefs.containsKey(_prefKeyColor)) {
          setPrimaryColor(Color(prefs.getInt(_prefKeyColor)));
        }
      });
    }
  }

  Color _primaryColor = Colors.blue;
  int _counter = 0;

  static _AppState of(BuildContext context) =>
      context.ancestorStateOfType(const TypeMatcher<_AppState>());

  /// Sets the primary color of the example app.
  void setPrimaryColor(Color color) {
    setState(() {
      _primaryColor = color;
    });
    _saveColor();
  }

  void _saveColor() async {
    if (Platform.isMacOS) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKeyColor, _primaryColor.value);
    }
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
    // Currently, the menubar plugin is only implemented on macOS and linux.
    if (!Platform.isMacOS && !Platform.isLinux) {
      return;
    }
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
        // Specify a font to reduce potential issues with the
        // example behaving differently on different platforms.
        fontFamily: 'Roboto',
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

  void _changePrimaryThemeColor(BuildContext context) {
    final colorPanel = ColorPanel.instance;
    if (!colorPanel.showing) {
      colorPanel.show((color) {
        _AppState.of(context).setPrimaryColor(color);
        // Setting the primary color to a non-opaque color raises an exception.
      }, showAlpha: false);
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
                      style: Theme.of(context).textTheme.display1,
                    ),
                    TextInputTestWidget(),
                    FileChooserTestWidget(),
                    URLLauncherTestWidget(),
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
          onPressed: () async {
            String initialDirectory;
            if (Platform.isMacOS) {
              initialDirectory =
                  (await getApplicationDocumentsDirectory()).path;
            }
            file_chooser.showOpenPanel(
              (result, paths) {
                Scaffold.of(context).showSnackBar(SnackBar(
                  content: Text(_resultTextForFileChooserOperation(
                      _FileChooserType.open, result, paths)),
                ));
              },
              allowsMultipleSelection: true,
              initialDirectory: initialDirectory,
            );
          },
        ),
      ],
    );
  }
}

/// A widget containing controls to test the url launcher plugin.
class URLLauncherTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ButtonBar(
      alignment: MainAxisAlignment.center,
      children: <Widget>[
        new FlatButton(
          child: const Text('OPEN ON GITHUB'),
          onPressed: () {
            url_launcher
                .launch('https://github.com/google/flutter-desktop-embedding');
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

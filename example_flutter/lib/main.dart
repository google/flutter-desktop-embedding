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
import 'package:color_panel/color_panel.dart';
import 'package:file_chooser/file_chooser.dart' as file_chooser;

void main() => runApp(new MyApp());

/// Top level widget for the example application.
class MyApp extends StatefulWidget {
  /// Constructs a new app with the given [key].
  const MyApp({Key key}) : super(key: key);

  @override
  _AppState createState() => new _AppState();
}

class _AppState extends State<MyApp> {
  static _AppState of(BuildContext context) =>
      context.ancestorStateOfType(const TypeMatcher<_AppState>());
  Color _primaryColor = Colors.blue;

  void setPrimaryColor(Color color) {
    setState(() {
      _primaryColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: _primaryColor,
        accentColor: _primaryColor,
      ),
      home: _MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class _MyHomePage extends StatefulWidget {
  const _MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<_MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

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
        title: Text(widget.title),
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
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.display1,
            ),
            FileChooserTestWidget(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
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

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
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Keyboard test page for the example application.
class KeyboardTestPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _KeyboardTestPageState();
  }
}

class _KeyboardTestPageState extends State<KeyboardTestPage> {
  final List<String> _messages = [];

  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = new ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FocusScope.of(context).requestFocus(_focusNode);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
          title: new Text('Keyboard events test'),
          leading: new IconButton(
              icon: new Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              })),
      body: new RawKeyboardListener(
        focusNode: _focusNode,
        onKey: onKeyEvent,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _messages.length,
            itemBuilder: (_, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_messages[index]),
              );
            },
          ),
        ),
      ),
    );
  }

  void onKeyEvent(RawKeyEvent event) {
    bool isKeyDown;
    switch (event.runtimeType) {
      case RawKeyDownEvent:
        isKeyDown = true;
        break;
      case RawKeyUpEvent:
        isKeyDown = false;
        break;
      default:
        throw new Exception('Unexpected runtimeType of RawKeyEvent');
    }

    int keyCode;
    String logicalKey;
    String physicalKey;
    switch (event.data.runtimeType) {
      case RawKeyEventDataMacOs:
        final RawKeyEventDataMacOs data = event.data;
        keyCode = data.keyCode;
        logicalKey = data.logicalKey.debugName;
        physicalKey = data.physicalKey.debugName;
        break;
      // TODO(https://github.com/flutter/flutter/issues/37830): The Windows and Linux shells share a
      // GLFW implementation. Update once RawKeyEventDataWindows is implemented.
      case RawKeyEventDataLinux:
        final RawKeyEventDataLinux data = event.data;
        keyCode = data.keyCode;
        logicalKey = data.logicalKey.debugName;
        physicalKey = data.physicalKey.debugName;
        break;
      default:
        throw new Exception('Unsupported platform ${event.data.runtimeType}');
    }

    _addMessage('${isKeyDown ? 'KeyDown' : 'KeyUp'}: $keyCode \nLogical key: ${logicalKey}\n'
      'Physical key: ${physicalKey}');
  }

  void _addMessage(String message) {
    setState(() {
      _messages.add(message);
    });
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
    });
  }
}

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
  void initState() {
    super.initState();
    FocusScope.of(context).requestFocus(_focusNode);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
          title: new Text("Keyboard events test"),
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
          child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _messages.map((m) => new Text(m)).toList())),
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
    switch (event.data.runtimeType) {
      case RawKeyEventDataAndroid:
        final RawKeyEventDataAndroid data = event.data;
        keyCode = data.keyCode;
        break;
      default:
        throw new Exception('Unsupported platform');
    }

    _addMessage('${isKeyDown ? 'KeyDown' : 'KeyUp'}: $keyCode');
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

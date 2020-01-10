# custom_cursor

A Flutter plugin for Desktop that changes the mouse cursor.


## Installing 

### MacOS

Nothing needed, already good to go!

### Linux

Follow this guide on how to work with desktop plugins for linux:

https://github.com/google/flutter-desktop-embedding/tree/master/plugins

### Windows

Follow this guide on how to work with desktop plugins for windows:

https://github.com/google/flutter-desktop-embedding/tree/master/plugins


## Usage

#### Set Mouse Cursor

Update the system cursor.

You need to provide `CursorType` type to set the cursor too. (You can also add the cursor to the stack)

Avaliable cursors:

```dart
enum CursorType {
  arrow,
  cross,
  hand,
  resizeLeft,
  resizeRight,
  resizeDown,
  resizeUp,
  resizeLeftRight,
  resizeUpDown,
}

```

```dart
WindowUtils.setCursor(CursorType cursor);
```

On Windows you need to modify you win32_window.cc

```
LRESULT
Win32Window::MessageHandler(HWND hwnd, UINT const message, WPARAM const wparam,
                            LPARAM const lparam) noexcept
{
  auto window =
      reinterpret_cast<Win32Window *>(GetWindowLongPtr(hwnd, GWLP_USERDATA));

  if (window == nullptr)
  {
    return 0;
  }

  switch (message)
  {
  case WM_SETCURSOR:
    return TRUE;
```

Add this to the top of the switch statement:

```
 case WM_SETCURSOR:
    return TRUE;
```

#### Add Mouse Cursor To Stack

> MACOS ONLY

Add a new cursor to the mouse cursor stack.

You need to provide `CursorType` type to set the cursor too. (You can also add the cursor to the stack)

Avaliable cursors:

```dart
enum CursorType {
  arrow,
  cross,
  hand,
  resizeLeft,
  resizeRight,
  resizeDown,
  resizeUp,
  resizeLeftRight,
  resizeUpDown,
}

```

```dart
WindowUtils.addCursorToStack(CursorType cursor);
```

#### Remove Cursor From Stack

> MACOS ONLY

This will remove the top cursor from the stack.

```dart
WindowUtils.removeCursorFromStack();
```

#### Hide Cursor(s)

This will hide the all the cursors in the stack.

```dart
WindowUtils.hideCursor();
```

#### Reset Cursor

This will reset the system cursor.

```dart
WindowUtils.resetCursor();
```

#### Show Cursor(s)

This will show all the cursors in the stack.

```dart
WindowUtils.showCursor();
```

## Example

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:custom_cursor/custom_cursor.dart';

void main() {
  if (!kIsWeb && debugDefaultTargetPlatformOverride == null) {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  }
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        CustomCursor.setCursor(CursorType.arrow);
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Custom Cursor Example'),
        ),
        body: ListView(
          children: <Widget>[
            ListTile(
              title: const Text('Change Cursor'),
              subtitle: DropdownButton<CursorType>(
                value: CursorType.arrow,
                items: CursorType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(describeEnum(t)),
                        ))
                    .toList(),
                onChanged: CustomCursor.setCursor,
              ),
              trailing: IconButton(
                icon: Icon(Icons.close),
                onPressed: CustomCursor.resetCursor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


```

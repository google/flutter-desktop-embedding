# example

A new Flutter project.

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
import 'dart:async';

import 'package:flutter/services.dart';

class CustomCursor {
  static const MethodChannel _channel =
      const MethodChannel('custom_cursor');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}

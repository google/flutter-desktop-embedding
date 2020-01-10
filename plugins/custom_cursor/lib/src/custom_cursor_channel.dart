import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CustomCursor {
  static const MethodChannel _channel = MethodChannel('custom_cursor');

  /// Hides the current cursor(s)
  static Future<bool> hideCursor() {
    return _channel.invokeMethod<bool>('hideCursor');
  }

  // Unhides the current cursor(s)
  static Future<bool> showCursor() {
    return _channel.invokeMethod<bool>('showCursor');
  }

  /// Sets the current cursor
  static Future<bool> setCursor(CursorType cursor,
      {MacOSCursorType macOS, WindowsCursorType windows}) {
    return _channel.invokeMethod<bool>(
      'setCursor',
      {
        'type': _getCursor(cursor, macOS, windows),
        'update': false,
      },
    );
  }

  /// Adds a new cursor to the stack on [MacOS]
  static Future<bool> addCursorToStack(CursorType cursor,
      {MacOSCursorType macOS, WindowsCursorType windows}) {
    return _channel.invokeMethod<bool>(
      'setCursor',
      {
        'type': _getCursor(cursor, macOS, windows),
        'update': true,
      },
    );
  }

  /// Removes the top cursor from the stack on [MacOS]
  static Future<bool> removeCursorFromStack() {
    return _channel.invokeMethod<bool>('removeCursorFromStack');
  }

  /// Returns the current mouse stack count on [MacOS]
  static Future<int> mouseStackCount() {
    return _channel.invokeMethod<int>('mouseStackCount');
  }

  /// Resets the cursor back to default and resets the stack for [MacOS]
  static Future<bool> resetCursor() {
    return _channel.invokeMethod<bool>('resetCursor');
  }

  static String _getCursor(
      CursorType cursor, MacOSCursorType macOS, WindowsCursorType windows) {
    if (Platform.isMacOS) {
      if (macOS == null) {
        switch (cursor) {
          case CursorType.arrow:
            macOS = MacOSCursorType.arrow;
            break;
          case CursorType.cross:
            macOS = MacOSCursorType.crossHair;
            break;
          case CursorType.hand:
            macOS = MacOSCursorType.openHand;
            break;
          case CursorType.resizeLeft:
            macOS = MacOSCursorType.resizeLeft;
            break;
          case CursorType.resizeRight:
            macOS = MacOSCursorType.resizeRight;
            break;
          case CursorType.resizeDown:
            macOS = MacOSCursorType.resizeDown;
            break;
          case CursorType.resizeUp:
            macOS = MacOSCursorType.resizeUp;
            break;
          case CursorType.resizeLeftRight:
            macOS = MacOSCursorType.resizeLeftRight;
            break;
          case CursorType.resizeUpDown:
            macOS = MacOSCursorType.resizeUpDown;
            break;
        }
      }
      return describeEnum(macOS);
    }
    if (Platform.isWindows) {
      if (windows == null) {
        switch (cursor) {
          case CursorType.arrow:
            windows = WindowsCursorType.arrow;
            break;
          case CursorType.cross:
            windows = WindowsCursorType.cross;
            break;
          case CursorType.hand:
            windows = WindowsCursorType.hand;
            break;
          case CursorType.resizeLeftRight:
          case CursorType.resizeLeft:
          case CursorType.resizeRight:
            windows = WindowsCursorType.resizeWE;
            break;
          case CursorType.resizeUpDown:
          case CursorType.resizeDown:
          case CursorType.resizeUp:
            windows = WindowsCursorType.resizeNS;
            break;
        }
      }
      return describeEnum(windows);
    }
    return "none";
  }
}

enum DragPosition {
  top,
  left,
  right,
  bottom,
  topLeft,
  bottomLeft,
  topRight,
  bottomRight
}

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

enum MacOSCursorType {
  arrow,
  beamVertical,
  crossHair,
  closedHand,
  openHand,
  pointingHand,
  resizeLeft,
  resizeRight,
  resizeDown,
  resizeUp,
  resizeLeftRight,
  resizeUpDown,
  beamHorizontial,
  disappearingItem,
  notAllowed,
  dragLink,
  dragCopy,
  contextMenu,
}

enum WindowsCursorType {
  appStart,
  arrow,
  cross,
  hand,
  help,
  iBeam,
  no,
  resizeAll,
  resizeNESW,
  resizeNS,
  resizeNWSE,
  resizeWE,
  upArrow,
  wait,
}

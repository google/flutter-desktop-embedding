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
      return describeEnum(_setMacCursor(macOS, cursor));
    }
    if (Platform.isWindows) {
      return describeEnum(_setWindowsCursor(windows, cursor));
    }
    return "none";
  }

  static WindowsCursorType _setWindowsCursor(
      WindowsCursorType windows, CursorType cursor) {
    if (windows == null) {
      switch (cursor) {
        case CursorType.arrow:
          return WindowsCursorType.arrow;
        case CursorType.cross:
          return WindowsCursorType.cross;
        case CursorType.hand:
          return WindowsCursorType.hand;
        case CursorType.resizeLeftRight:
        case CursorType.resizeLeft:
        case CursorType.resizeRight:
          return WindowsCursorType.resizeWE;
        case CursorType.resizeUpDown:
        case CursorType.resizeDown:
        case CursorType.resizeUp:
          return WindowsCursorType.resizeNS;
      }
    }
    return windows;
  }

  static MacOSCursorType _setMacCursor(
      MacOSCursorType macOS, CursorType cursor) {
    if (macOS == null) {
      switch (cursor) {
        case CursorType.arrow:
          return MacOSCursorType.arrow;
        case CursorType.cross:
          return MacOSCursorType.crossHair;
        case CursorType.hand:
          return MacOSCursorType.openHand;
        case CursorType.resizeLeft:
          return MacOSCursorType.resizeLeft;
        case CursorType.resizeRight:
          return MacOSCursorType.resizeRight;
        case CursorType.resizeDown:
          return MacOSCursorType.resizeDown;
        case CursorType.resizeUp:
          return MacOSCursorType.resizeUp;
        case CursorType.resizeLeftRight:
          return MacOSCursorType.resizeLeftRight;
        case CursorType.resizeUpDown:
          return MacOSCursorType.resizeUpDown;
      }
    }
    return macOS;
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

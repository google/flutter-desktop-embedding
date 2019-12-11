// Copyright 2019 Google LLC
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
import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';

import 'platform_window.dart';
import 'screen.dart';

/// The name of the plugin's platform channel.
const String _windowSizeChannelName = 'flutter/windowsize';

/// The method name to request information about the available screens.
///
/// Returns a list of screen info maps; see keys below.
const String _getScreenListMethod = 'getScreenList';

/// The method name to request information about the window containing the
/// Flutter instance.
///
/// Returns a list of window info maps; see keys below.
const String _getWindowInfoMethod = 'getWindowInfo';

/// The method name to set the frame of a window.
///
/// Takes a frame array, as documented for the value of _frameKey.
const String _setWindowFrameMethod = 'setWindowFrame';

/// The method name to set the minimum size of a window.
///
/// Takes a window size array, as documented for the value of _windowSizeKey.
const String _setWindowMinimumSizeMethod = 'setWindowMinimumSize';

/// The method name to set the maximum size of a window.
///
/// Takes a window size array, as documented for the value of _windowSizeKey.
const String _setWindowMaximumSizeMethod = 'setWindowMaximumSize';

/// The method name to get the minimum size of a window.
///
/// Returns a window size array, as documented for the value of _windowSizeKey.
const String _getWindowMinimumSizeMethod = 'getWindowMinimumSize';

/// The method name to get the maximum size of a window.
///
/// Returns a window size array, as documented for the value of _windowSizeKey.
const String _getWindowMaximumSizeMethod = 'getWindowMaximumSize';

// Keys for screen and window maps returned by _getScreenListMethod.

/// The frame of a screen or window. The value is a list of four doubles:
///   [left, top, width, height]
const String _frameKey = 'frame';

/// The size of a window. The value is a list of two doubles:
///   [width, height]
const String _windowSizeKey = 'windowSize';

/// The frame of a screen available for use by applications. The value format
/// is the same as _frameKey's.
///
/// Only used for screens.
const String _visibleFrameKey = 'visibleFrame';

/// The scale factor for a screen or window, as a double.
///
/// This is the number of pixels per screen coordinate, and thus the ratio
/// between sizes as seen by Flutter and sizes in native screen coordinates.
const String _scaleFactorKey = 'scaleFactor';

/// The screen containing this window, if any. The value is a screen map, or
/// null if the window is not visible on a screen.
///
/// Only used for windows.
///
/// If a window is on multiple screens, it is up to the platform to decide which
/// screen to report.
const String _screenKey = 'screen';

/// A singleton object that handles the interaction with the platform channel.
class WindowSizeChannel {
  /// Private constructor.
  WindowSizeChannel._();

  final MethodChannel _platformChannel =
      const MethodChannel(_windowSizeChannelName);

  /// The static instance of the menu channel.
  static final WindowSizeChannel instance = new WindowSizeChannel._();

  /// Returns a list of screens.
  Future<List<Screen>> getScreenList() async {
    final screenList = <Screen>[];
    final response = await _platformChannel.invokeMethod(_getScreenListMethod);

    for (final screenInfo in response) {
      screenList.add(_screenFromInfoMap(screenInfo));
    }
    return screenList;
  }

  /// Returns information about the window containing this Flutter instance.
  Future<PlatformWindow> getWindowInfo() async {
    final response = await _platformChannel.invokeMethod(_getWindowInfoMethod);

    return PlatformWindow(_rectFromLTWHList(response[_frameKey].cast<double>()),
        response[_scaleFactorKey], _screenFromInfoMap(response[_screenKey]));
  }

  /// Sets the frame of the window containing this Flutter instance, in
  /// screen coordinates.
  ///
  /// The platform may adjust the frame as necessary if the provided frame would
  /// cause significant usability issues (e.g., a window with no visible portion
  /// that can be used to move the window).
  void setWindowFrame(Rect frame) async {
    assert(!frame.isEmpty, 'Cannot set window frame to an empty rect.');
    assert(frame.isFinite, 'Cannot set window frame to a non-finite rect.');
    await _platformChannel.invokeMethod(_setWindowFrameMethod,
        [frame.left, frame.top, frame.width, frame.height]);
  }

  // Window minimum size unconstrained is passed over the channel as -1.
  double _setWindowMinSizeUnconstrainedCheck(double size) {
    if (size > 0) {
      return size;
    }
    return -1;
  }

  /// Sets the minimum size of the window containing this Flutter instance.
  void setWindowMinSize(Size size) async {
    await _platformChannel.invokeMethod(_setWindowMinimumSizeMethod, [
      _setWindowMinSizeUnconstrainedCheck(size.width),
      _setWindowMinSizeUnconstrainedCheck(size.height),
    ]);
  }

  // Window maximum size unconstrained is passed over the channel as -1.
  double _setWindowMaxSizeUnconstrainedCheck(double size) {
    if (size != double.infinity) {
      return size;
    }
    return -1;
  }

  /// Sets the maximum size of the window containing this Flutter instance.
  void setWindowMaxSize(Size size) async {
    await _platformChannel.invokeMethod(_setWindowMaximumSizeMethod, [
      _setWindowMaxSizeUnconstrainedCheck(size.width),
      _setWindowMaxSizeUnconstrainedCheck(size.height),
    ]);
  }

  // Window minimum size unconstrained is passed over the channel as -1.
  double _getWindowMinSizeUnconstrainedCheck(double size) {
    if (size != -1) {
      return size;
    }
    return 0;
  }

  /// Gets the minimum size of the window containing this Flutter instance.
  Future<Size> getWindowMinSize() async {
    final response =
        await _platformChannel.invokeMethod(_getWindowMinimumSizeMethod);
    return _sizeFromWHList(
      List<double>.from(
        response[_windowSizeKey]
            .cast<double>()
            .map(_getWindowMinSizeUnconstrainedCheck),
      ),
    );
  }

  // Window maximum size unconstrained is passed over the channel as -1.
  double _getWindowMaxSizeUnconstrainedCheck(double size) {
    if (size != -1) {
      return size;
    }
    return double.infinity;
  }

  /// Gets the maximum size of the window containing this Flutter instance.
  Future<Size> getWindowMaxSize() async {
    final response =
        await _platformChannel.invokeMethod(_getWindowMaximumSizeMethod);
    return _sizeFromWHList(
      List<double>.from(
        response[_windowSizeKey]
            .cast<double>()
            .map(_getWindowMaxSizeUnconstrainedCheck),
      ),
    );
  }

  /// Given an array of the form [left, top, width, height], return the
  /// corresponding [Rect].
  ///
  /// Used for frame deserialization in the platform channel.
  Rect _rectFromLTWHList(List<double> ltwh) {
    return Rect.fromLTWH(ltwh[0], ltwh[1], ltwh[2], ltwh[3]);
  }

  /// Given an array of the form [width, height], return the corresponding
  /// [Size].
  ///
  /// Used for window size deserialization in the platform channel.
  Size _sizeFromWHList(List<double> wh) {
    return Size(wh[0], wh[1]);
  }

  /// Given a map of information about a screen, return the corresponding
  /// [Screen] object, or null.
  ///
  /// Used for screen deserialization in the platform channel.
  Screen _screenFromInfoMap(Map<dynamic, dynamic> map) {
    if (map == null) {
      return null;
    }
    return Screen(
        _rectFromLTWHList(map[_frameKey].cast<double>()),
        _rectFromLTWHList(map[_visibleFrameKey].cast<double>()),
        map[_scaleFactorKey]);
  }
}

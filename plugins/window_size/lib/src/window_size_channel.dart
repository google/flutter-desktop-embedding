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

// Plugin channel constants. See common/channel_constants.h for details.
const String _windowSizeChannelName = 'flutter/windowsize';
const String _getScreenListMethod = 'getScreenList';
const String _getCurrentScreenMethod = 'getCurrentScreen';
const String _getWindowInfoMethod = 'getWindowInfo';
const String _setWindowFrameMethod = 'setWindowFrame';
const String _frameKey = 'frame';
const String _visibleFrameKey = 'visibleFrame';
const String _scaleFactorKey = 'scaleFactor';
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
    try {
      final screenList = <Screen>[];
      final response =
          await _platformChannel.invokeMethod(_getScreenListMethod);

      for (final screenInfo in response) {
        screenList.add(_screenFromInfoMap(screenInfo));
      }
      return screenList;
    } on PlatformException catch (e) {
      print('Platform exception getting screen list: ${e.message}');
    }
    return <Screen>[];
  }

  /// Returns information about the window containing this Flutter instance.
  Future<PlatformWindow> getWindowInfo() async {
    try {
      final response =
          await _platformChannel.invokeMethod(_getWindowInfoMethod);

      return PlatformWindow(
          _rectFromLTWHList(response[_frameKey].cast<double>()),
          response[_scaleFactorKey],
          _screenFromInfoMap(response[_screenKey]));
    } on PlatformException catch (e) {
      print('Platform exception getting window info: ${e.message}');
    }
    return null;
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
    try {
      await _platformChannel.invokeMethod(_setWindowFrameMethod,
          [frame.left, frame.top, frame.width, frame.height]);
    } on PlatformException catch (e) {
      print('Platform exception setting window frame: ${e.message}');
    }
  }

  /// Given an array of the form [left, top, width, height], return the
  /// corresponding [Rect].
  ///
  /// Used for frame deserialization in the platform channel.
  Rect _rectFromLTWHList(List<double> ltwh) {
    return Rect.fromLTWH(ltwh[0], ltwh[1], ltwh[2], ltwh[3]);
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

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

import 'screen.dart';

// Plugin channel constants. See common/channel_constants.h for details.
const String _windowSizeChannelName = 'flutter/windowsize';
const String _getScreenListMethod = 'WindowSize.GetScreens';
const String _frameKey = 'frame';
const String _visibleFrameKey = 'visibleFrame';
const String _scaleFactorKey = 'scaleFactor';

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
      await _platformChannel
          .invokeMethod(_getScreenListMethod)
          .then((response) {
        final List<Screen> screenList =
            response?.cast<Map>()?.map((screenInfo) {
          final frame = screenInfo[_frameKey];
          final visibleFrame = screenInfo[_visibleFrameKey];
          return Screen(
              Rect.fromLTWH(frame[0], frame[1], frame[2], frame[3]),
              Rect.fromLTWH(visibleFrame[0], visibleFrame[1], visibleFrame[2],
                  visibleFrame[3]),
              screenInfo[_scaleFactorKey]);
        });
        if (screenList == null) {
          return <Screen>[];
        }
        return screenList;
      });
    } on PlatformException catch (e) {
      print('Platform exception getting screen list: ${e.message}');
    }
    return <Screen>[];
  }
}

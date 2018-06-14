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
import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';

// Plugin channel constants. See common/channel_constants.h for details.
const String _kColorPanelChannel = 'flutter/colorpanel';
const String _kShowColorPanelMethod = 'ColorPanel.Show';
const String _kHideColorPanelMethod = 'ColorPanel.Hide';
const String _kColorPanelColorSelectedCallback =
    'ColorPanel.ColorSelectedCallback';
const String _kColorPanelClosedCallback = 'ColorPanel.ClosedCallback';
const String _kRedKey = 'red';
const String _kGreenKey = 'green';
const String _kBlueKey = 'blue';

const MethodChannel _platformChannel =
    const MethodChannel(_kColorPanelChannel, const JSONMethodCodec());

/// A callback to pass to [ColorPanel] to receive user-selected colors.
typedef ColorPanelCallback = void Function(Color color);

/// Provides access to an OS-provided color chooser.
///
/// This class is a singleton, since the OS may not allow multiple color panels
/// simultaneously.
class ColorPanel {
  ColorPanelCallback _callback;

  /// Private constructor.
  ColorPanel._() {
    _platformChannel.setMethodCallHandler(_wrappedColorPanelCallback);
  }

  /// The static instance of the panel.
  static ColorPanel instance = new ColorPanel._();

  /// Whether or not the panel is showing.
  bool get showing => _callback != null;

  /// Shows the color panel.
  ///
  /// [callback] will be called when the user selects a color; it can be called
  /// an number of times depending on the interaction model of the native
  /// panel.
  ///
  /// It is an error to call [show] if the panel is already showing.
  void show(ColorPanelCallback callback) {
    try {
      if (!showing) {
        _callback = callback;
        _platformChannel.invokeMethod(_kShowColorPanelMethod);
      } else {
        throw new StateError('Color panel is already shown');
      }
    } on PlatformException catch (e) {
      print('PLATFORM ERROR: ${e.message}');
    }
  }

  /// Hides the color panel.
  ///
  /// It is an error to call [hide] if the panel is not showing. Since
  /// the panel can be closed by the user, you should always check
  /// [showing] before calling [hide].
  void hide() {
    try {
      if (showing) {
        _platformChannel.invokeMethod(_kHideColorPanelMethod);
        _callback = null;
      } else {
        throw new StateError('Color panel is already hidden');
      }
    } on PlatformException catch (e) {
      print('PLATFORM ERROR: ${e.message}');
    }
  }

  /// Given a color component value from 0-1, converts it to an int
  /// from 0-255.
  int _colorComponentFloatToInt(num value) {
    const colorMax = 255;
    return (value * colorMax).toInt();
  }

  /// Mediates between the platform channel callback and the client callback.
  Future<Null> _wrappedColorPanelCallback(MethodCall methodCall) async {
    if (methodCall.method == _kColorPanelClosedCallback) {
      _callback = null;
    } else if (_callback != null &&
        methodCall.method == _kColorPanelColorSelectedCallback) {
      try {
        final Map<String, dynamic> arg =
            methodCall.arguments.cast<String, dynamic>();
        if (arg != null) {
          _callback(Color.fromARGB(
              255,
              _colorComponentFloatToInt(arg[_kRedKey]),
              _colorComponentFloatToInt(arg[_kGreenKey]),
              _colorComponentFloatToInt(arg[_kBlueKey])));
        }
      } on Exception catch (e, s) {
        print('Exception in callback handler: $e\n$s');
      }
    }
  }
}

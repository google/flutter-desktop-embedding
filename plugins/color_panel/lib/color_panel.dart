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

/// The name of the plugin's platform channel.
const String _kColorPanelChannel = 'flutter/colorpanel';

/// The method name to instruct the native plugin to show the panel.
const String _kShowColorPanelMethod = 'ColorPanel.Show';
/// The method name to instruct the native plugin to hide the panel.
const String _kHideColorPanelMethod = 'ColorPanel.Hide';
/// The method name for the Dart-side callback that receives color values.
const String _kColorPanelColorSelectedCallback =
    'ColorPanel.ColorSelectedCallback';
/// The method name for the Dart-side callback that is called if the panel is
/// closed from the UI, rather than via a call to kHideColorPanelMethod.
const String _kColorPanelClosedCallback = 'ColorPanel.ClosedCallback';

/// The argument to show an opacity modifier on the panel. Default is true.
const String _kColorPanelShowAlpha = 'ColorPanel.ShowAlpha';

// Keys for the ARGB color map sent to kColorPanelCallback.
// The values should be numbers between 0 and 1.
const String _kRedKey = 'red';
const String _kGreenKey = 'green';
const String _kBlueKey = 'blue';
// Platform implementations should return 1 if the opacity slider is not shown.
const String _kAlphaKey = 'alpha';

const MethodChannel _platformChannel = const MethodChannel(_kColorPanelChannel);

/// A callback to pass to [ColorPanel] to receive user-selected colors.
typedef ColorPanelCallback = void Function(Color color);

/// Provides access to an OS-provided color chooser.
///
/// This class is a singleton, since the OS may not allow multiple color panels
/// simultaneously.
class ColorPanel {
  /// Private constructor.
  ColorPanel._() {
    _platformChannel.setMethodCallHandler(_wrappedColorPanelCallback);
  }

  ColorPanelCallback _callback;

  /// The static instance of the panel.
  static ColorPanel instance = new ColorPanel._();

  /// Whether or not the panel is showing.
  bool get showing => _callback != null;

  /// Shows the color panel.
  ///
  /// [callback] will be called when the user selects a color; it can be called
  /// an number of times depending on the interaction model of the native
  /// panel. Set [showAlpha] to false to hide the color opacity modifier UI.
  ///
  /// It is an error to call [show] if the panel is already showing.
  void show(ColorPanelCallback callback, {bool showAlpha = true}) {
    try {
      if (!showing) {
        _callback = callback;
        _platformChannel.invokeMethod(
            _kShowColorPanelMethod, {_kColorPanelShowAlpha: showAlpha});
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
              _colorComponentFloatToInt(arg[_kAlphaKey]),
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

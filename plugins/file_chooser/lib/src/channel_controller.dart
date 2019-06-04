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
import 'package:flutter/services.dart';

import 'callbacks.dart';

/// The name of the plugin's platform channel.
const String _kChannelName = 'flutter/filechooser';

/// The method name to instruct the native plugin to show an open panel.
const String _kShowOpenPanelMethod = 'FileChooser.Show.Open';
/// The method name to instruct the native plugin to show a save panel.
const String _kShowSavePanelMethod = 'FileChooser.Show.Save';

// Configuration parameters for file chooser panels:

/// The path, as a string, for initial directory to display. Default behavior is
/// left to the OS if not provided.]
const String _kInitialDirectoryKey = 'initialDirectory';
/// The initial file name that should appears in the file chooser. Defaults to
/// an empty string if not provided.
const String _kInitialFileNameKey = 'initialFileName';
/// An array of UTI or file extension strings a panel is allowed to choose.
const String _kAllowedFileTypesKey = 'allowedFileTypes';
/// The text that appears on the panel's confirmation button. If not provided,
/// the OS default is used.
const String _kConfirmButtonTextKey = 'confirmButtonText';

// Configuration parameters that only apply to open panels:

/// A boolean indicating whether a panel should allow choosing multiple file
/// paths. Defaults to false if not set.
const String _kAllowsMultipleSelectionKey = 'allowsMultipleSelection';
/// A boolean indicating whether a panel should allow choosing directories
/// instead of files. Defaults to false if not set.
const String _kCanChooseDirectoriesKey = 'canChooseDirectories';

/// A File chooser type.
enum FileChooserType {
  /// An open panel, for choosing one or more files to open.
  open,

  /// A save panel, for choosing where to save a file.
  save,
}

/// A set of configuration options for a file chooser.
class FileChooserConfigurationOptions {
  /// Creates a new configuration options object with the given settings.
  const FileChooserConfigurationOptions(
      {this.initialDirectory,
      this.initialFileName,
      this.allowedFileTypes,
      this.allowsMultipleSelection,
      this.canSelectDirectories,
      this.confirmButtonText});

  // See the constants above for documentation; these correspond exactly to
  // the configuration parameters defined in the channel protocol.
  final String initialDirectory; // ignore: public_member_api_docs
  final String initialFileName; // ignore: public_member_api_docs
  final List<String> allowedFileTypes; // ignore: public_member_api_docs
  final bool allowsMultipleSelection; // ignore: public_member_api_docs
  final bool canSelectDirectories; // ignore: public_member_api_docs
  final String confirmButtonText; // ignore: public_member_api_docs

  /// Returns the configuration as a map that can be passed as the
  /// arguments to invokeMethod for [_kShowOpenPanelMethod] or
  /// [_kShowSavePanelMethod].
  Map<String, dynamic> asInvokeMethodArguments() {
    final args = <String, dynamic>{};
    if (initialDirectory != null && initialDirectory.isNotEmpty) {
      args[_kInitialDirectoryKey] = initialDirectory;
    }
    if (allowsMultipleSelection != null) {
      args[_kAllowsMultipleSelectionKey] = allowsMultipleSelection;
    }
    if (canSelectDirectories != null) {
      args[_kCanChooseDirectoriesKey] = canSelectDirectories;
    }
    if (allowedFileTypes != null && allowedFileTypes.isNotEmpty) {
      args[_kAllowedFileTypesKey] = allowedFileTypes;
    }
    if (confirmButtonText != null && confirmButtonText.isNotEmpty) {
      args[_kConfirmButtonTextKey] = confirmButtonText;
    }
    if (confirmButtonText != null && confirmButtonText.isNotEmpty) {
      args[_kConfirmButtonTextKey] = confirmButtonText;
    }
    if (initialFileName != null && initialFileName.isNotEmpty) {
      args[_kInitialFileNameKey] = initialFileName;
    }
    return args;
  }
}

/// A singleton object that controls file-choosing interactions with macOS.
class FileChooserChannelController {
  FileChooserChannelController._();

  /// The platform channel used to manage native file chooser affordances.
  final _channel = new MethodChannel(_kChannelName);

  /// A reference to the singleton instance of the class.
  static final FileChooserChannelController instance =
      new FileChooserChannelController._();

  /// Shows a file chooser of [type] configured with [options], calling
  /// [callback] when it completes.
  void show(FileChooserType type, FileChooserConfigurationOptions options,
      FileChooserCallback callback) {
    try {
      final methodName = type == FileChooserType.open
          ? _kShowOpenPanelMethod
          : _kShowSavePanelMethod;
      _channel
          .invokeMethod(methodName, options.asInvokeMethodArguments())
          .then((response) {
        final paths = response?.cast<String>();
        final result =
            paths == null ? FileChooserResult.cancel : FileChooserResult.ok;
        callback(result, paths);
      });
    } on PlatformException catch (e) {
      print('File chooser plugin failure: ${e.message}');
    } on Exception catch (e, s) {
      print('Exception during file chooser operation: $e\n$s');
    }
  }
}

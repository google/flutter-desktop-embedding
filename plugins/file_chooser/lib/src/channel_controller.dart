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

// Plugin channel constants. See common/channel_constants.h for details.
const String _kChannelName = 'flutter/filechooser';
const String _kShowOpenPanelMethod = 'FileChooser.Show.Open';
const String _kShowSavePanelMethod = 'FileChooser.Show.Save';
const String _kInitialDirectoryKey = 'initialDirectory';
const String _kInitialFileNameKey = 'initialFileName';
const String _kAllowedFileTypesKey = 'allowedFileTypes';
const String _kConfirmButtonTextKey = 'confirmButtonText';
const String _kAllowsMultipleSelectionKey = 'allowsMultipleSelection';
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

  // See channel_constants.h for documentation; these correspond exactly to
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

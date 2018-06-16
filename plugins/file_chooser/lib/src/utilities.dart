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
import 'callbacks.dart';
import 'channel_controller.dart';

/// Shows a file chooser for selecting paths to one or more existing files.
///
/// A number of configuration options are available:
/// - [initialDirectory] defaults the panel to the given directory path.
/// - [allowedFileTypes] restricts selection to the given file types.
/// - [allowsMultipleSelection] controls whether or not more than one file
///   can be selected. Defaults to single file selection if unset.
/// - [canSelectDirectories] allows choosing directories instead of files.
///   Defaults to file selection if unset.
/// - [confirmButtonText] overrides the button that confirms selection.
void showOpenPanel(FileChooserCallback callback,
    {String initialDirectory,
    List<String> allowedFileTypes,
    bool allowsMultipleSelection,
    bool canSelectDirectories,
    String confirmButtonText}) {
  final options = FileChooserConfigurationOptions(
      initialDirectory: initialDirectory,
      allowedFileTypes: allowedFileTypes,
      allowsMultipleSelection: allowsMultipleSelection,
      canSelectDirectories: canSelectDirectories,
      confirmButtonText: confirmButtonText);
  FileChooserChannelController.instance
      .show(FileChooserType.open, options, callback);
}

/// Shows a file chooser for selecting a save path.
///
/// A number of configuration options are available:
/// - [initialDirectory] defaults the panel to the given directory path.
/// - [suggestedFileName] provides an initial value for the save filename.
/// - [allowedFileTypes] restricts selection to the given file types.
/// - [confirmButtonText] overrides the button that confirms selection.
void showSavePanel(FileChooserCallback callback,
    {String initialDirectory,
    String suggestedFileName,
    List<String> allowedFileTypes,
    String confirmButtonText}) {
  final options = FileChooserConfigurationOptions(
      initialDirectory: initialDirectory,
      initialFileName: suggestedFileName,
      allowedFileTypes: allowedFileTypes,
      confirmButtonText: confirmButtonText);
  FileChooserChannelController.instance
      .show(FileChooserType.save, options, callback);
}

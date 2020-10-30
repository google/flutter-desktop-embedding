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
import 'channel_controller.dart';
import 'filter_group.dart';
import 'result.dart';

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
Future<FileChooserResult> showOpenPanel({
  String initialDirectory,
  List<FileTypeFilterGroup> allowedFileTypes,
  bool allowsMultipleSelection,
  bool canSelectDirectories,
  String confirmButtonText,
}) async {
  final options = FileChooserConfigurationOptions(
      initialDirectory: initialDirectory,
      allowedFileTypes: allowedFileTypes,
      allowsMultipleSelection: allowsMultipleSelection,
      canSelectDirectories: canSelectDirectories,
      confirmButtonText: confirmButtonText);
  return FileChooserChannelController.instance
      .show(FileChooserType.open, options);
}

/// Shows a file chooser for selecting a save path.
///
/// A number of configuration options are available:
/// - [initialDirectory] defaults the panel to the given directory path.
/// - [suggestedFileName] provides an initial value for the save filename.
/// - [allowedFileTypes] restricts selection to the given file types.
/// - [confirmButtonText] overrides the button that confirms selection.
Future<FileChooserResult> showSavePanel(
    {String initialDirectory,
    String suggestedFileName,
    List<FileTypeFilterGroup> allowedFileTypes,
    String confirmButtonText}) async {
  final options = FileChooserConfigurationOptions(
      initialDirectory: initialDirectory,
      initialFileName: suggestedFileName,
      allowedFileTypes: allowedFileTypes,
      confirmButtonText: confirmButtonText);
  return FileChooserChannelController.instance
      .show(FileChooserType.save, options);
}

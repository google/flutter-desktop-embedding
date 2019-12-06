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

/// The result of a file chooser operation.
class FileChooserResult {
  /// Creates a new result object with the given state and paths.
  const FileChooserResult({this.paths, this.canceled});

  /// Whether or not the file chooser operation was canceled by the user.
  final bool canceled;

  /// A list of file paths chosen by the user. If [canceled] is true, the list
  /// should always be empty.
  final List<String> paths;
}

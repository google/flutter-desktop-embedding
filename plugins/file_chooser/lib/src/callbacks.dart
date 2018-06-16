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

/// Encodes the ending state for a user's interaction with the file chooser,
/// indicating whether the operation was cancelled or completed (OK'd).
enum FileChooserResult {
  /// The user dismissed the file chooser without completing the operation.
  cancel,

  /// The user completed the operation with the file chooser.
  ok,
}

/// Method signature for file chooser callbacks.
///  - parameter result: an enum indicating whether a user selected a file path.
///  - parameter paths: a list of file paths chosen by the user.
typedef FileChooserCallback = void Function(
    FileChooserResult result, List<String> paths);

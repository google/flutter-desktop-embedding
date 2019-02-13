// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the 'License');
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an 'AS IS' BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Utilities related to the Flutter tree and/or engine that are used by
// multiple tools.

import 'dart:io';

import 'package:path/path.dart' as path;

/// The last Flutter hash that's known to be required; a branch that doesn't
/// contain this commit will either fail to build, or fail to run.
///
/// This should be updated whenever a new dependency is introduced (e.g., a
/// required embedder API addition or implementation fix).
const String lastKnownRequiredFlutterCommit =
    '8101862bdbb8168b37ad270ad7ed4ab473287dff';

/// Returns the path to the root of this repository.
///
/// Relies on the known location of dart_tools/bin within the repo, and the fact
/// that all the tools are direct children of that directory.
String getRepositoryRoot() {
  final scriptUri = Platform.script;
  return new File.fromUri(scriptUri).parent.parent.parent.parent.path;
}

/// Returns the path that should be assumed for the location of the Flutter
/// tree if an explicit path is not provided.
///
/// This corresponds to the location suggested in the project documentation
/// (currently, as a sibling of this repository).
String getDefaultFlutterRoot() {
  return path.join(path.dirname(getRepositoryRoot()), 'flutter');
}

/// Returns the engine hash from [file] as a String, or null.
///
/// If the file is missing, or cannot be read, returns null.
Future<String> readHashFileIfPossible(File file) async {
  if (!file.existsSync()) {
    return null;
  }
  try {
    return (await file.readAsString()).trim();
  } on FileSystemException {
    // If the file can't be read for any reason, just treat it as missing.
    return null;
  }
}

/// Returns the engine version hash for the Flutter tree at [flutterRoot],
/// or null if it can't be found.
Future<String> engineHashForFlutterTree(String flutterRoot) async {
  final versionFile =
      new File(path.join(flutterRoot, 'bin', 'internal', 'engine.version'));
  return await readHashFileIfPossible(versionFile);
}

/// If there is an engine override file, returns the engine build type given in
/// the file, otherwise returns null.
Future<String> getEngineOverrideBuildType() async {
  final overrideFile = File(path.join(getRepositoryRoot(), 'engine_override'));
  if (!overrideFile.existsSync()) {
    return null;
  }
  return (await overrideFile.readAsString()).trim();
}

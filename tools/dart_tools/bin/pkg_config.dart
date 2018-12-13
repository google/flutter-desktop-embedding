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

// This script wraps pkg-config, parsing out the different types of flags and
// outputing them in a form directly consumable by GN. It is modeled on
// Chromium's pkg-config.py, pared down for the needs of this project.

import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) {
  final pkgConfigArguments = ['--cflags', '--libs']..addAll(arguments);
  List<String> allFlags;
  Process.run('pkg-config', pkgConfigArguments).then((results) {
    exitCode = results.exitCode;
    if (exitCode == 0) {
      allFlags = results.stdout.toString().trim().split(' ');
      // JSON.encode's output for lists of strings is compatible with GN's
      // parsing.
      print(json.encode(parseFlags(allFlags)));
    } else {
      print(results.stderr);
    }
  });
}

/// Parses [flags], and returns them in an array suitable for output to GN:
/// [includes, cflags, libraries, library directories]
List<List<String>> parseFlags(List<String> flags) {
  final includes = <String>[];
  final cflags = <String>[];
  final libs = <String>[];
  final libDirs = <String>[];
  for (final flag in flags) {
    if (flag.startsWith('-l')) {
      libs.add(flag.substring(2));
    } else if (flag.startsWith('-L')) {
      libDirs.add(flag.substring(2));
    } else if (flag.startsWith('-I')) {
      includes.add(flag.substring(2));
    } else if (flag.startsWith('-Wl')) {
      // Don't allow libraries to control ld flags.  These should be specified
      // only in build files.
      continue;
    } else if (flag == '-pthread') {
      // Remove pthread since it's always set for libraries at the GN level
      // anyway.
      continue;
    } else {
      cflags.add(flag);
    }
  }
  return [includes, cflags, libs, libDirs];
}

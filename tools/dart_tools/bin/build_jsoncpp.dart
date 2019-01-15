// Copyright 2018 Google LLC
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

// This script builds jsoncpp using Visual Studio 2017 in a provided directory.
// An additional directory can be provided which will have to built library
// copied to it. Optionally using the --debug flag will build in debug mode.

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import '../lib/run_command.dart';

Future<void> main(List<String> arguments) async {
  if (!Platform.isWindows) {
    throw new Exception('Building jsoncpp libraries is only available on '
        'windows.');
  }

  final parser = new ArgParser()..addFlag('debug', abbr: 'd', negatable: false);
  final args = parser.parse(arguments);

  if (args.rest.isEmpty) {
    throw new Exception('One argument must be provided, the directory where '
        'jsoncpp is downloaded.');
  }

  final downloadDirectory = args.rest[0];
  final debug = args['debug'];

  final buildDirectory = '$downloadDirectory/makefiles/msvc2017';
  await buildLibrary(buildDirectory, debug: debug);

  if (args.rest.length != 2) {
    print('Copy directory not provided.');
    exit(0);
  }

  final copyDirectory = args.rest[1];
  await copyLibraryToOutputDirectory(buildDirectory, copyDirectory,
      debug: debug);
}

Future<void> buildLibrary(String buildDirectory, {bool debug}) async {
  final arguments = [
    'msbuild',
    'lib_json.vcxproj',
    '/p:Platform=x64',
  ];
  if (Platform.environment['APPVEYOR'] != 'True') {
    arguments.insert(0, 'vcvars64.bat 1> nul &&');
  }
  if (!debug) {
    arguments.add('/p:Configuration=Release');
  }

  final command = arguments[0];
  arguments.removeAt(0);

  await runCommand(command, arguments,
      workingDirectory: buildDirectory, runInShell: true);
}

Future<void> copyLibraryToOutputDirectory(
    String buildDirectory, String copyDirectory,
    {bool debug}) async {
  final outputDirectory = "$buildDirectory/x64/${debug ? "Debug" : "Release"}";
  final outputLibrary =
      "$outputDirectory/json_vc71_libmt${debug ? "d" : ""}.lib";

  await File(outputLibrary)
      .copy(path.join(copyDirectory, path.basename(outputLibrary)));
}

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

// This script runs the necessary Flutter commands to build the Flutter assets
// that need to be packaged in an embedding application.
// It should be called with one argument, which is the directory of the
// Flutter application to build.

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import '../lib/flutter_utils.dart';
import '../lib/run_command.dart';

Future<void> main(List<String> arguments) async {
  final parser = new ArgParser()
    ..addOption('flutter_root',
        help: 'The root of the Flutter tree to run \'flutter\' from.\n'
            'Defaults to a "flutter" directory next to this repository.',
        defaultsTo: getDefaultFlutterRoot())
    ..addFlag('help', help: 'Prints this usage message.', negatable: false);
  ArgResults parsedArguments;

  try {
    parsedArguments = parser.parse(arguments);
  } on ArgParserException {
    printUsage(parser);
    exit(1);
  }
  if (parsedArguments.rest.length != 1) {
    printUsage(parser);
    exit(1);
  }
  final flutterApplicationDir = parsedArguments.rest[0];

  final flutterName = Platform.isWindows ? 'flutter.bat' : 'flutter';
  final flutterBinary =
      path.join(parsedArguments['flutter_root'], 'bin', flutterName);
  if (!File(flutterBinary).existsSync()) {
    print("Error: No flutter binary at '$flutterBinary'");
    exit(1);
  }

  final buildArguments = ['build', 'bundle'];

  // Add --local-engine if an override is specified. --local-engine-src-path
  // isn't provided since per
  // https://github.com/flutter/flutter/wiki/The-flutter-tool
  // it's not required if the engine directory is next to the flutter directory,
  // which is currently the only configuration this project supports for local
  // engines.
  final engineOverride = await getEngineOverrideBuildType();
  if (engineOverride != null) {
    buildArguments.insertAll(0, ['--local-engine', engineOverride]);
  }

  await runCommand(flutterBinary, buildArguments,
      workingDirectory: flutterApplicationDir);
}

/// Prints usage info for this utility.
void printUsage(ArgParser argParser) {
  print('Usage: build_flutter_assets [options] '
      '<fluter application directory>\n');
  print(argParser.usage);
}

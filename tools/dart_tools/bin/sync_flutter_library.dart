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

// This script copies the Flutter artifacts (library and support files)
// necessary to build Flutter.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import '../lib/flutter_utils.dart';
import '../lib/git_utils.dart';

const osNameToToolPlatform = <String, String>{
  'linux': 'linux-x64',
  'macos': 'darwin-x64',
  'windows': 'windows-x64',
};

Future<void> main(List<String> arguments) async {
  final parser = new ArgParser()
    ..addOption('platform',
        help: 'The platform to download the Flutter library for.\n'
            'Defaults to the current platform.',
        allowed: osNameToToolPlatform.keys,
        defaultsTo: Platform.operatingSystem)
    ..addOption('flutter_root',
        help: 'The root of the Flutter tree to get the engine version from.\n'
            'Ignored if an engine_override file is present.\n'
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

  if (parsedArguments['help'] || parsedArguments.rest.length != 1) {
    printUsage(parser);
    exit(parsedArguments['help'] ? 0 : 1);
  }

  final targetPlatform = osNameToToolPlatform[parsedArguments['platform']];
  final String flutterRoot = parsedArguments['flutter_root'];
  final outputRoot = path.canonicalize(path.absolute(parsedArguments.rest[0]));

  // Flutter version checks on application builds should catch most cases, but
  // check for a minimum Flutter hash here in case someone is building plugins
  // directly using an old Flutter tree.
  final containsRequiredCommit =
      await gitHeadContainsCommit(flutterRoot, lastKnownRequiredFlutterCommit);
  if (!containsRequiredCommit) {
    print('Flutter library update aborted: Your Flutter tree is too '
        'old for use with this project. Please update to a newer version of '
        'Flutter, then try again.\n\n'
        'Note that this may require switching to Flutter master. See:\n'
        'https://github.com/flutter/flutter/wiki/Flutter-build-release-channels');
    exit(1);
  }

  // Currently the only local engine configuration that is supported is a
  // directory called 'engine' next to the 'flutter' directory (see
  // https://github.com/flutter/flutter/wiki/The-flutter-tool#using-a-locally-built-engine-with-the-flutter-tool
  // for context), so --local-engine-src-path is never passed.
  final localEngine = await getEngineOverrideBuildType();
  await runFlutterCommand(flutterRoot, [
    'unpack',
    '--target-platform=$targetPlatform',
    '--cache-dir=$outputRoot',
    if (localEngine != null) '--local-engine=$localEngine',
  ]);
}

/// Prints usage info for this utility.
void printUsage(ArgParser argParser) {
  print('Usage: sync_flutter_library [options] <output directory>\n');
  print(argParser.usage);
}

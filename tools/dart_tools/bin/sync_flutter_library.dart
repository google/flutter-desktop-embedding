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

// This script downloads a specific version of the prebuilt Flutter library
// for a desktop platform.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import '../lib/flutter_artifact_fetcher.dart';
import '../lib/flutter_utils.dart';
import '../lib/git_utils.dart';

Future<void> main(List<String> arguments) async {
  final parser = new ArgParser()
    ..addOption('platform',
        help: 'The platform to download the Flutter library for.\n'
            'Defaults to the current platform.',
        allowed: FlutterArtifactFetcher.supportedPlatforms,
        defaultsTo: Platform.operatingSystem)
    ..addOption('flutter_root',
        help: 'The root of the Flutter tree to get the engine version from.\n'
            'Ignored if --hash is provided, or if an engine_override file '
            'is present.\n'
            'Defaults to a "flutter" directory next to this repository.',
        defaultsTo: getDefaultFlutterRoot())
    ..addFlag('skip_min_version_check',
        help: 'If set, skips the initial check that the Flutter tree whose '
            'engine version is being fetched is new enough for the framework.')
    ..addOption(
      'hash',
      // Note: engine_override takes precedence over this flag so that
      // individual developers can easily use engine_override for development
      // even if the project is configured to use --hash.
      help: 'The hash of the engine version to use.\n'
          'This is only required if you want to override the version;\n'
          'normally you should use flutter_root instead.\n'
          'Ignored if an engine_override is present\n',
    )
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

  final String platform = parsedArguments['platform'];
  final String flutterRoot = parsedArguments['flutter_root'];
  final outputRoot = path.canonicalize(path.absolute(parsedArguments.rest[0]));

  // TODO: Consider making a setup script that should be run after any update,
  // which checks/fetches dependencies, and moving this check there. For now,
  // do it here since it's a hook that's run on every build.
  if (!parsedArguments['skip_min_version_check']) {
    final containsRequiredCommit = await gitHeadContainsCommit(
        flutterRoot, lastKnownRequiredFlutterCommit);
    if (!containsRequiredCommit) {
      print('Flutter library update aborted: Your Flutter tree is too '
          'old for use with this project. Please update to a newer version of '
          'Flutter, then try again.\n\n'
          'Note that this may require switching to Flutter master. See:\n'
          'https://github.com/flutter/flutter/wiki/Flutter-build-release-channels');
      exit(1);
    }
  }

  final fetcher = FlutterArtifactFetcher(platform, flutterRoot);
  const artifact = FlutterArtifactType.flutter;

  final engineOverrideBuildType = await getEngineOverrideBuildType();
  if (engineOverrideBuildType == null) {
    final String targetHash =
        parsedArguments['hash'] ?? await engineHashForFlutterTree(flutterRoot);
    if (!await fetcher.fetchArtifact(artifact, outputRoot,
        engineHash: targetHash)) {
      exit(1);
    }
  } else {
    // Currently the only configuration that is supported is a directory
    // called 'engine' next to the 'flutter' directory (see
    // https://github.com/flutter/flutter/wiki/The-flutter-tool#using-a-locally-built-engine-with-the-flutter-tool
    // for context).
    final engineRoot = path.join(path.dirname(flutterRoot), 'engine');
    if (!await fetcher.copyLocalArtifact(
        artifact, engineRoot, outputRoot, engineOverrideBuildType)) {
      exit(1);
    }
  }
}

/// Prints usage info for this utility.
void printUsage(ArgParser argParser) {
  print('Usage: sync_flutter_library [options] <output directory>\n');
  print(argParser.usage);
}

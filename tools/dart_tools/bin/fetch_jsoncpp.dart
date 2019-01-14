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

// This script downloads a specific version of jsoncpp with Visual Studio 2017
// support into a provided directory.

import 'dart:io';

import '../lib/run_command.dart';

// For the fork containing V2017 support. Once
// https://github.com/open-source-parsers/jsoncpp/pull/853
// has landed, this should use the jsoncpp repository.
const String gitRepo = 'https://github.com/clarkezone/jsoncpp.git';
const String pinnedVersion = '3ae7e8073a425c93329c8577a3c813c206322ca4';

Future<void> main(List<String> arguments) async {
  if (!Platform.isWindows) {
    throw new Exception('Fetching jsoncpp libraries is only available on '
        'windows.');
  }

  if (arguments.length != 1) {
    throw new Exception('One argument should be passed, the directory to '
        'download jsoncpp to.');
  }

  final downloadDirectory = arguments[0];

  if (Directory(downloadDirectory).existsSync()) {
    print('$downloadDirectory already exists; skipping clone');
  } else {
    await runCommand('git', [
      'clone',
      gitRepo,
      downloadDirectory,
    ]);
  }

  await runCommand(
      'git',
      [
        'checkout',
        pinnedVersion,
      ],
      workingDirectory: downloadDirectory);
}

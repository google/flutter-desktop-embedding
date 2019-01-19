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

// This script downloads a specific version of jsoncpp into a provided
// directory.

import 'dart:io';

import '../lib/run_command.dart';

const String gitRepo = 'https://github.com/open-source-parsers/jsoncpp.git';
const String pinnedVersion = '21a418563406acb42484eff33da0a354a671effc';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    throw new Exception('One argument should be passed, the directory to '
        'download jsoncpp to.');
  }

  final downloadDirectory = arguments[0];

  final checkoutExisted = Directory(downloadDirectory).existsSync();
  if (checkoutExisted) {
    print('$downloadDirectory already exists; skipping clone');
  } else {
    await runCommand('git', [
      'clone',
      gitRepo,
      downloadDirectory,
    ]);
  }

  final checkoutExitCode =
      await pinVersion(downloadDirectory, allowFail: checkoutExisted);

  if (checkoutExitCode != 0 && checkoutExisted) {
    // The tree may be from before the switch to the actual jsoncpp repo.
    // If that's the case, fix it and try again.
    // TODO: Remove this sometime after 2019-03-15. By that point most
    // existing checkouts will likely have been updated.
    final originChanged = await fixOriginIfNecessary(downloadDirectory);
    if (originChanged) {
      print('Updated jsoncpp to point to main repository. Re-syncing...');
      // Pull from the new origin, then re-pin.
      await runCommand(
          'git',
          [
            'fetch',
          ],
          workingDirectory: downloadDirectory);
      await pinVersion(downloadDirectory);
    }
  }
}

/// Checks out pinnedVersion in the existing checkout in [repositoryRoot].
Future<int> pinVersion(String repositoryRoot, {bool allowFail = false}) async {
  return await runCommand(
      'git',
      [
        'checkout',
        pinnedVersion,
      ],
      workingDirectory: repositoryRoot,
      allowFail: allowFail);
}

/// If 'origin' in [repositoryRoot] points to the previous remote, switch it
/// to the actual jsoncpp repository.
///
/// Returns true if the origin was incorrect and has been successfully changed.
Future<bool> fixOriginIfNecessary(String checkoutDirectory,
    {bool allowFail = false}) async {
  // If origin's URL doesn't match the regex, set-url will print an error and
  // fail, so run it silently to avoid confusing log messages if this is run
  // when it's not needed (which is a no-op).
  final exitCode = await runCommand(
      'git',
      [
        'remote',
        'set-url',
        'origin',
        gitRepo,
        '.*clarkezone.*',
      ],
      workingDirectory: checkoutDirectory,
      allowFail: true,
      suppressOutput: true);

  return exitCode == 0;
}

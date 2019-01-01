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

import 'dart:io';

import 'package:args/args.dart';

Future<void> main(List<String> arguments) async {
  if (!Platform.isWindows) {
    throw new Exception('Building jsoncpp libraries is only available on '
        'windows.');
  }

  final parser = new ArgParser()
    ..addFlag('debug', abbr: 'd', negatable: false);
  final args = parser.parse(arguments);

  final downloadDirectory = arguments[0];
  final debug = args['debug'];

  await Process.run('git', [
    'init',
    downloadDirectory,
  ]);

  await Process.run(
      'git',
      [
        'remote',
        'add',
        'origin',
        'https://github.com/clarkezone/jsoncpp.git',
      ],
      workingDirectory: downloadDirectory);

  await Process.run(
      'git',
      [
        'fetch',
      ],
      workingDirectory: downloadDirectory);

  await Process.run(
      'git',
      [
        'checkout',
        '3ae7e8073a425c93329c8577a3c813c206322ca4',
      ],
      workingDirectory: downloadDirectory);

  final jsoncppBuildProcess = await Process.run(
      'vcvars64.bat &&',
      [
        'msbuild',
        'lib_json.vcxproj',
        !debug ? '/p:Configuration=Release' : '',
      ],
      workingDirectory: '$downloadDirectory/makefiles/msvc2017',
      runInShell: true);

  if (jsoncppBuildProcess.exitCode != 0) {
    print(jsoncppBuildProcess.stdout);
    print(jsoncppBuildProcess.stderr);
    throw new Exception('jsoncpp Build Failed');
  }
}

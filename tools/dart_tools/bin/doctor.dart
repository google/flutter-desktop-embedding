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

// This script does simple validation of the users build environment, ensuring
// that dependencies are installed and in the path. Intended for helping people
// self-debug issues getting started, and for simplifying support.

import 'dart:io';

import '../lib/run_command.dart';

class _Dependency {
  const _Dependency(this.name, this.verificationCommand,
      [this.verificationCommandArguments]);
  final String name;
  final String verificationCommand;
  final List<String> verificationCommandArguments;
}

Future<void> main() async {
  print('Checking dependencies:\n');

  final dependencies = [
    _Dependency('git', 'git', ['--version']),
  ];
  if (Platform.isWindows || Platform.isLinux) {
    dependencies
      ..add(_Dependency('GN', 'gn', ['--version']))
      ..add(_Dependency('ninja', 'ninja', ['--version']));
  }
  if (Platform.isLinux) {
    dependencies.add(_Dependency('GCC', 'g++', ['--version']));
    dependencies.add(_Dependency('libraries', 'pkg-config', [
      '--exists',
      '--print-errors',
      'gtk+-3.0',
    ]));
  }
  if (Platform.isWindows) {
    dependencies
        .add(_Dependency('Visual Studio command line tools', 'vcvars64.bat'));
  }

  final failures = <String>[];
  for (final dependency in dependencies) {
    if (!await verifyDependency(dependency)) {
      failures.add(dependency.name);
    }
  }

  print('====================');
  if (failures.isEmpty) {
    print('No issues found');
  } else {
    print('The following dependencies have issues: ${failures.join(', ')}');
    print('Please check project READMEs for information on dependencies.');
  }
}

Future<bool> verifyDependency(_Dependency dependency) async {
  print('--------------------');
  print('Verifying ${dependency.name}...');
  final succeeded = await runCommand(dependency.verificationCommand,
          dependency.verificationCommandArguments ?? [],
          allowFail: true) ==
      0;
  print('');
  return succeeded;
}

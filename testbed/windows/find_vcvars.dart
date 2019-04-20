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

// This script attempts to find vcvars64.bat, and if successful outputs its
// path and returns 0. Otherwise, it prints nothing and returns 1.
import 'dart:io';

int main() {
  final programDir = Platform.environment['PROGRAMFILES(X86)'];
  final pathPrefix = '$programDir\\Microsoft Visual Studio';
  const pathSuffix = 'VC\\Auxiliary\\Build\\vcvars64.bat';
  final years = ['2017', '2019'];
  final flavors = ['Community', 'Professional', 'Enterprise', 'Preview'];
  for (final year in years) {
    for (final flavor in flavors) {
      final testPath = '$pathPrefix\\$year\\$flavor\\$pathSuffix';
      if (File(testPath).existsSync()) {
        print(testPath);
        return 0;
      }
    }
  }
  return 1;
}

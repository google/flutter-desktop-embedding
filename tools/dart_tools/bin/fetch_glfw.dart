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

// This script downloads a prebuilt glfw library into a provided directory.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';

const String glfwArchiveUrlString =
    'http://github.com/glfw/glfw/releases/download/3.2.1/glfw-3.2.1.bin.WIN64.zip';

const List<String> requiredFiles = [
  'glfw-3.2.1.bin.WIN64/include/GLFW/glfw3.h',
  'glfw-3.2.1.bin.WIN64/lib-vc2015/glfw3.lib',
];

Future<void> main(List<String> arguments) async {
  if (!Platform.isWindows) {
    throw new Exception('Prebuilt glfw3 libraries are only available on '
        'windows.');
  }

  if (arguments.length != 1) {
    throw new Exception('Only one argument should be passed, the directory to '
        'download glfw to.');
  }

  final outputDirectory = arguments[0];

  if (await downloadExists(outputDirectory)) {
    print('GLFW files already exist.');
    exit(0);
  }

  final archiveData = await downloadLibrary();

  await new Directory(outputDirectory).create(recursive: true);

  await extractRequiredFiles(archiveData, outputDirectory);
}

Future<bool> downloadExists(String outputDirectory) async {
  var existingFiles = 0;
  for (final file in requiredFiles) {
    if (File('$outputDirectory/${path.basename(file)}').existsSync()) {
      existingFiles++;
    }
  }

  if (existingFiles == requiredFiles.length) {
    return true;
  }
  return false;
}

Future<List<int>> downloadLibrary() async {
  final archiveUri = Uri.parse(glfwArchiveUrlString);

  final httpClient = new HttpClient();
  final response =
      await httpClient.getUrl(archiveUri).then((request) => request.close());
  final archiveData = <int>[];
  await for (final data in response) {
    archiveData.addAll(data);
  }
  httpClient.close();
  return archiveData;
}

Future<void> extractRequiredFiles(
    List<int> archiveData, String outputDirectory) async {
  final archive = new ZipDecoder().decodeBytes(archiveData);
  for (final file in archive) {
    if (!requiredFiles.contains(file.name)) {
      continue;
    }

    final extractedFile =
        new File(path.join(outputDirectory, path.basename(file.name)));
    await extractedFile.writeAsBytes(file.content);
  }
}

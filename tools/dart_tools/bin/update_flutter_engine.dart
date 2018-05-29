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

// This script downloads a specific version of the prebuilt Flutter engine
// library for a desktop platform.

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';

// The filename stored next to a downloaded engine library to indicate its
// version.
const lastDownloadedVersionFile = '.last_engine_version';

// The base URL for downloading prebuilt engine archives.
final engineArchiveBaseUrlString =
    'https://storage.googleapis.com/flutter_infra/flutter';

// Simple container for platform-specific information.
class PlatformInfo {
  // The subpath on storage.googleapis.com for a platform's engine archive.
  final String archiveSubpath;
  // The extracted engine library filename for a platform.
  final String libraryFile;

  PlatformInfo(this.archiveSubpath, this.libraryFile);
}

final platformInfo = {
  'linux':
      new PlatformInfo('linux-x64/linux-x64-embedder', 'libflutter_engine.so'),
  'macos': new PlatformInfo(
      'darwin-x64/FlutterEmbedder.framework.zip', 'FlutterEmbedder.framework'),
  'windows': new PlatformInfo(
      'windows-x64/windows-x64-embedder.zip', 'flutter_engine.dll'),
};

main(List<String> arguments) async {
  var parser = new ArgParser();
  parser.addOption('platform',
      help: 'The platform to download the engine for.\n'
          'Defaults to the current platform.',
      allowed: platformInfo.keys,
      defaultsTo: Platform.operatingSystem);
  parser.addOption('flutter_root',
      help: 'The root of a the Flutter tree to get the engine version from.\n'
          'Ignored if --hash is provided.\n'
          'Defaults to a "flutter" directory next to this repository.',
      defaultsTo: path.join(path.dirname(getRepositoryParent()), 'flutter'));
  parser.addOption(
    'hash',
    help: 'The hash of the engine version to use.\n'
        'This is only required if you want to override the version;\n'
        'normally you should use flutter_root instead.',
  );
  parser.addFlag('help', help: 'Prints this usage message.', negatable: false);
  ArgResults parsedArguments;
  try {
    parsedArguments = parser.parse(arguments);
  } catch (_) {
    printUsage(parser);
    exit(1);
  }

  if (parsedArguments['help'] || parsedArguments.rest.length != 1) {
    printUsage(parser);
    exit(parsedArguments['help'] ? 0 : 1);
  }

  try {
    final platform = parsedArguments['platform'];
    final outputRoot =
        path.canonicalize(path.absolute(parsedArguments.rest[0]));
    final targetHash = parsedArguments['hash'] ??
        await engineHashForFlutterTree(parsedArguments['flutter_root']);
    final libraryFile = platformInfo[platform].libraryFile;

    final currentHash = await lastDownloadedEngineHash(outputRoot, platform);
    if (currentHash == null || targetHash != currentHash) {
      await downloadEngine(targetHash, platform, outputRoot);
      await setLastDownloadedEngineHash(outputRoot, targetHash);
      print('Downloaded $libraryFile version ${targetHash}.');
    } else {
      print('$libraryFile version ${targetHash} already present.');
    }
  } catch (e) {
    print(e);
    exit(1);
  }
}

printUsage(ArgParser argParser) {
  print('Usage: update_flutter_engine [options] <output directory>\n');
  print(argParser.usage);
}

// Returns the path to the parent directory of this project's repository.
// Relies on the known location of this script within the repo.
String getRepositoryParent() {
  final scriptUri = Platform.script;
  return new File.fromUri(scriptUri).parent.parent.parent.parent.path;
}

// Returns the engine version hash for the Flutter tree at [flutterRoot],
// or null if it can't be found.
engineHashForFlutterTree(String flutterRoot) async {
  final versionFile =
      new File(path.join(flutterRoot, 'bin', 'internal', 'engine.version'));
  try {
    return (await versionFile.readAsString()).trim();
  } catch (_) {
    return null;
  }
}

// Returns a File object for the file containing the last downloaded engine
// hash in [directory].
File lastDownloadedHashEngineFile(String directory) {
  return new File(path.join(directory, lastDownloadedVersionFile));
}

// Returns the last downloaded engine's hash, or null if there is no
// last downloaded engine.
lastDownloadedEngineHash(String downloadDirectory, String platform) async {
  final engineFilePath =
      path.join(downloadDirectory, platformInfo[platform].libraryFile);
  final engineExists = (await FileSystemEntity.type(engineFilePath)) !=
      FileSystemEntityType.notFound;
  if (!engineExists) {
    return null;
  }
  try {
    return (await lastDownloadedHashEngineFile(downloadDirectory)
            .readAsString())
        .trim();
  } catch (_) {
    return null;
  }
}

// Writes [hash] to the file that stores the last downloaded engine
// hash in [directory].
setLastDownloadedEngineHash(String directory, String hash) async {
  await lastDownloadedHashEngineFile(directory).writeAsString(hash);
}

// Downloads the version of the engine specified by [hash] for [platform] to
// the [outputDirectory], extracting and removing the archived version.
downloadEngine(String hash, String platform, String outputDirectory) async {
  final archiveUri = Uri.parse('$engineArchiveBaseUrlString/$hash/'
      '${platformInfo[platform].archiveSubpath}');

  var httpClient = new HttpClient();
  var response = await httpClient
      .getUrl(archiveUri)
      .then((HttpClientRequest request) => request.close());
  var archiveData = <int>[];
  await for (final data in response) {
    archiveData.addAll(data);
  }
  httpClient.close();
  if (archiveData.length < 500) {
    throw 'Engine version $hash is not available.';
  }
  try {
    await extractEngineArchive(archiveData, platform, outputDirectory);
  } catch (e) {
    throw 'Unable to extract archive: ${e}';
  }
}

// Extracts the [archiveData] to [outputDirectory].
extractEngineArchive(
    List<int> archiveData, String platform, String outputDirectory) async {
  await new Directory(outputDirectory).create(recursive: true);

  if (platform == 'macos') {
    // Reconstructing a macOS framework, which is a tree containing symlinks,
    // is non-trivial. Rather than recreate all that logic, just call out to
    // unzip. Since unzip is shippde with macOS, this should always work.

    // Unwrap the outer zip via Archive to avoid starting an extra process.
    Archive archive = new ZipDecoder().decodeBytes(archiveData);
    if (archive.numberOfFiles() == 1 && archive[0].name.endsWith('.zip')) {
      archiveData = archive[0].content;
    }
    await unzipMacOSEngineFramework(archiveData, outputDirectory);
  } else {
    // Windows and Linux have flat archives, so can be easily extracted via
    // Archive.
    Archive archive = new ZipDecoder().decodeBytes(archiveData);
    for (ArchiveFile file in archive) {
      if (file.name.endsWith('.zip')) {
        extractEngineArchive(file.content, platform, outputDirectory);
      } else {
        var extractedFile = new File(path.join(outputDirectory, file.name));
        await extractedFile.writeAsBytes(file.content);
      }
    }
  }
}

// Unzips the engine framework archive at [archivePath] in [outputDirectory]
// by invoking /usr/bin/unzip, removing any previous version of the framework
// that already exists there.
unzipMacOSEngineFramework(List<int> archiveData, String outputDirectory) async {
  final temporaryArchiveFile =
      new File(path.join(outputDirectory, 'engine_archive.zip'));
  final targetPath =
      path.join(outputDirectory, platformInfo['macos'].libraryFile);

  // Delete the framework if it is already present.
  var frameworkFile = new Directory(targetPath);
  if (await frameworkFile.exists()) {
    await frameworkFile.delete(recursive: true);
  }

  // Temporarily write the data to a file, since unzip doesn't accept piped
  // input, then delete the file.
  await temporaryArchiveFile.writeAsBytes(archiveData);
  ProcessResult result = await Process
      .run('/usr/bin/unzip', [temporaryArchiveFile.path, '-d', targetPath]);
  await temporaryArchiveFile.delete();
  if (result.exitCode != 0) {
    throw 'Failed to unzip archive (exit ${result.exitCode}:\n'
        '${result.stdout}\n---\n${result.stderr}';
  }
}

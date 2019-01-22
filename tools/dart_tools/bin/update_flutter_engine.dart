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

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';

import '../lib/flutter_utils.dart';
import '../lib/git_utils.dart';

/// The filename stored next to a downloaded engine library to indicate its
/// version.
const String lastDownloadedVersionFile = '.last_engine_version';

/// The base URL for downloading prebuilt engine archives.
const String engineArchiveBaseUrlString =
    'https://storage.googleapis.com/flutter_infra/flutter';

/// Simple container for platform-specific information.
class PlatformInfo {
  PlatformInfo(this.archiveSubpath, this.libraryFiles);

  /// The subpath on storage.googleapis.com for a platform's engine archive.
  final String archiveSubpath;

  /// The top-level extracted files for a platform.
  ///
  /// The first item in the array is the library itself, and any other items
  /// are supporting files (headers, symbols, etc.).
  final List<String> libraryFiles;
}

/// Exceptions for known error cases in updating the engine.
class EngineUpdateException implements Exception {
  EngineUpdateException(this.message);

  final String message;
}

/// PlatformInfo for each supported platform.
final Map<String, PlatformInfo> platformInfo = {
  'linux': new PlatformInfo('linux-x64/linux-x64-embedder', [
    'libflutter_engine.so',
    'flutter_embedder.h',
  ]),
  'macos': new PlatformInfo('darwin-x64/FlutterEmbedder.framework.zip', [
    'FlutterEmbedder.framework',
  ]),
  'windows': new PlatformInfo('windows-x64/windows-x64-embedder.zip', [
    'flutter_engine.dll',
    'flutter_engine.dll.exp',
    'flutter_engine.dll.lib',
    'flutter_engine.dll.pdb',
    'flutter_embedder.h',
  ]),
};

Future<void> main(List<String> arguments) async {
  final parser = new ArgParser()
    ..addOption('platform',
        help: 'The platform to download the engine for.\n'
            'Defaults to the current platform.',
        allowed: platformInfo.keys,
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
    bool containsRequiredCommit = await gitHeadContainsCommit(
        flutterRoot, lastKnownRequiredFlutterCommit);
    if (!containsRequiredCommit) {
      print('Flutter engine update aborted: Your Flutter tree is too '
          'old for use with this project. Please update to a newer version of '
          'Flutter, then try again.\n\n'
          'Note that this may require switching to Flutter master. See:\n'
          'https://github.com/flutter/flutter/wiki/Flutter-build-release-channels');
      exit(1);
    }
  }

  final engineOverrideBuildType = await getEngineOverrideBuildType();
  if (engineOverrideBuildType == null) {
    final String targetHash =
        parsedArguments['hash'] ?? await engineHashForFlutterTree(flutterRoot);
    if (!await syncPrebuiltEngine(targetHash, platform, outputRoot)) {
      exit(1);
    }
  } else {
    // Currently the only configuration that is supported is a directory
    // called 'engine' next to the 'flutter' directory (see
    // https://github.com/flutter/flutter/wiki/The-flutter-tool#using-a-locally-built-engine-with-the-flutter-tool
    // for context), so look there for the build output.
    final buildOutputDirectory = path.join(path.dirname(flutterRoot), 'engine',
        'src', 'out', engineOverrideBuildType);
    if (!await copyLocalEngine(buildOutputDirectory, platform, outputRoot)) {
      exit(1);
    }
  }
}

/// Prints usage info for this utility.
void printUsage(ArgParser argParser) {
  print('Usage: update_flutter_engine [options] <output directory>\n');
  print(argParser.usage);
}

/// Checks [outputRoot] for an already-downloaded engine with the given
/// [engineHash], and if it's either not present or not up-to-date, attempts
/// to download the prebuilt engine for [platform] with that hash.
///
/// Returns true if the engine was successfully downloaded, or was already
/// present with the correct hash.
Future<bool> syncPrebuiltEngine(
  String engineHash,
  String platform,
  String outputRoot,
) async {
  try {
    final libraryFile = platformInfo[platform].libraryFiles[0];

    final currentHash = await lastDownloadedEngineHash(outputRoot, platform);
    if (currentHash == null || engineHash != currentHash) {
      await downloadEngine(engineHash, platform, outputRoot);
      await setLastDownloadedEngineHash(outputRoot, engineHash);
      print('Downloaded $libraryFile version $engineHash.');
    } else {
      print('$libraryFile version $engineHash already present.');
    }
  } on EngineUpdateException catch (e) {
    print(e.message);
    return false;
  }
  return true;
}

/// Copies the locally built engine for [platform], as well as any supporting
/// files that would be present in the prebuilt version, from
/// [buildOutputDirectory] to [targetDirectory].
///
/// Returns true if successful, or false if any necessary files were missing or
/// couldn't be copied.
Future<bool> copyLocalEngine(String buildOutputDirectory, String platform,
    String targetDirectory) async {
  await new Directory(targetDirectory).create(recursive: true);

  // On macOS, delete the existing framework if any before copying in the new
  // one, since it's a directory. On the other platforms, where files are just
  // individual files, this isn't necessary since copying over existing files
  // will do the right thing.
  if (platform == 'macos') {
    await copyMacOSEngineFramework(
        path.join(buildOutputDirectory, platformInfo[platform].libraryFiles[0]),
        targetDirectory);
  } else {
    for (final filename in platformInfo[platform].libraryFiles) {
      final sourceFile = File(path.join(buildOutputDirectory, filename));
      await sourceFile.copy(path.join(targetDirectory, filename));
    }
  }

  print('Copied local engine from $buildOutputDirectory.');

  // Update the hash file to indicate that it's a local build, so that it's
  // obvious where it came from.
  await setLastDownloadedEngineHash(
      targetDirectory, 'local engine: $buildOutputDirectory');

  return true;
}

/// Returns the engine version hash for the Flutter tree at [flutterRoot],
/// or null if it can't be found.
Future<String> engineHashForFlutterTree(String flutterRoot) async {
  final versionFile =
      new File(path.join(flutterRoot, 'bin', 'internal', 'engine.version'));
  return await readHashFileIfPossible(versionFile);
}

/// Returns a File object for the file containing the last downloaded engine
/// hash in [directory].
File lastDownloadedHashEngineFile(String directory) {
  return new File(path.join(directory, lastDownloadedVersionFile));
}

/// Returns the last downloaded engine's hash, or null if there is no
/// last downloaded engine.
Future<String> lastDownloadedEngineHash(
    String downloadDirectory, String platform) async {
  final engineFilePath =
      path.join(downloadDirectory, platformInfo[platform].libraryFiles[0]);
  final engineExists = (FileSystemEntity.typeSync(engineFilePath)) !=
      FileSystemEntityType.notFound;
  if (!engineExists) {
    return null;
  }
  final hashFile = lastDownloadedHashEngineFile(downloadDirectory);
  return await readHashFileIfPossible(hashFile);
}

/// Returns the engine hash from [file] as a String, or null.
///
/// If the file is missing, or cannot be read, returns null.
Future<String> readHashFileIfPossible(File file) async {
  if (!file.existsSync()) {
    return null;
  }
  try {
    return (await file.readAsString()).trim();
  } on FileSystemException {
    // If the file can't be read for any reason, just treat it as missing.
    return null;
  }
}

/// Writes [hash] to the file that stores the last downloaded engine
/// hash in [directory].
Future<void> setLastDownloadedEngineHash(String directory, String hash) async {
  await lastDownloadedHashEngineFile(directory).writeAsString(hash);
}

/// Downloads the version of the engine specified by [hash] for [platform] to
/// the [outputDirectory], extracting and removing the archived version.
Future<void> downloadEngine(
    String hash, String platform, String outputDirectory) async {
  final archiveUri = Uri.parse('$engineArchiveBaseUrlString/$hash/'
      '${platformInfo[platform].archiveSubpath}');

  final httpClient = new HttpClient();
  final response =
      await httpClient.getUrl(archiveUri).then((request) => request.close());
  final archiveData = <int>[];
  await for (final data in response) {
    archiveData.addAll(data);
  }
  httpClient.close();
  if (archiveData.length < 500) {
    throw new EngineUpdateException('Engine version $hash is not available.');
  }
  try {
    await extractEngineArchive(archiveData, platform, outputDirectory);
  } on ArchiveException catch (e) {
    throw new EngineUpdateException('Unable to extract archive: $e');
  }
}

/// Extracts the [archiveData] to [outputDirectory].
Future<void> extractEngineArchive(
    List<int> archiveData, String platform, String outputDirectory) async {
  await new Directory(outputDirectory).create(recursive: true);

  final archive = new ZipDecoder().decodeBytes(archiveData);
  if (platform == 'macos') {
    // Reconstructing a macOS framework, which is a tree containing symlinks,
    // is non-trivial. Rather than recreate all that logic, just call out to
    // unzip. Since unzip is shippde with macOS, this should always work.

    // Unwrap the outer zip via Archive to avoid starting an extra process.
    final isDoubleZipped =
        archive.numberOfFiles() == 1 && archive[0].name.endsWith('.zip');
    final List<int> innermostZipData =
        isDoubleZipped ? archive[0].content : archiveData;
    await unzipMacOSEngineFramework(innermostZipData, outputDirectory);
  } else {
    // Windows and Linux have flat archives, so can be easily extracted via
    // Archive.
    for (final file in archive) {
      if (file.name.endsWith('.zip')) {
        await extractEngineArchive(file.content, platform, outputDirectory);
      } else {
        final extractedFile = new File(path.join(outputDirectory, file.name));
        await extractedFile.writeAsBytes(file.content);
      }
    }
  }
}

/// Unzips the engine framework archive [archiveData] in [outputDirectory]
/// by invoking /usr/bin/unzip.
///
/// Removes any previous version of the framework that already exists there.
Future<void> unzipMacOSEngineFramework(
    List<int> archiveData, String outputDirectory) async {
  final temporaryArchiveFile =
      new File(path.join(outputDirectory, 'engine_archive.zip'));
  final targetPath =
      path.join(outputDirectory, platformInfo['macos'].libraryFiles[0]);

  await deleteFrameworkIfPresent(targetPath);

  // Temporarily write the data to a file, since unzip doesn't accept piped
  // input, then delete the file.
  await temporaryArchiveFile.writeAsBytes(archiveData);
  final result = await Process.run(
      '/usr/bin/unzip', [temporaryArchiveFile.path, '-d', targetPath]);
  await temporaryArchiveFile.delete();
  if (result.exitCode != 0) {
    throw new EngineUpdateException(
        'Failed to unzip archive (exit ${result.exitCode}:\n'
        '${result.stdout}\n---\n${result.stderr}');
  }
}

/// Copies the framework at [frameworkPath] to [targetDirectory]
/// by invoking 'cp -R'.
///
/// The shelling out is done to avoid complications with preserving special
/// files (e.g., symbolic links) in the framework structure.
///
/// Removes any previous version of the framework that already exists in the
/// target directory.
Future<void> copyMacOSEngineFramework(
    String frameworkPath, String targetDirectory) async {
  await deleteFrameworkIfPresent(
      path.join(targetDirectory, path.basename(frameworkPath)));

  final result =
      await Process.run('cp', ['-R', frameworkPath, targetDirectory]);
  if (result.exitCode != 0) {
    throw new EngineUpdateException(
        'Failed to copy framework (exit ${result.exitCode}:\n'
        '${result.stdout}\n---\n${result.stderr}');
  }
}

/// Recursively deletes the framework at [frameworkPath], if it exists.
Future<void> deleteFrameworkIfPresent(String frameworkPath) async {
  // Ensure that the path is a framework, to minimize the potential for
  // catastrophic deletion bugs with bad arguments.
  if (path.extension(frameworkPath) != '.framework') {
    throw new EngineUpdateException(
        'Attempted to delete a non-framework directory: $frameworkPath');
  }

  final directory = new Directory(frameworkPath);
  if (directory.existsSync()) {
    await directory.delete(recursive: true);
  }
}

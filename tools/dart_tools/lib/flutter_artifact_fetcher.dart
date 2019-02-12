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

import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';

import 'flutter_utils.dart';

/// The base URL for downloading prebuilt engine archives.
const String _flutterArtifactBaseUrlString =
    'https://storage.googleapis.com/flutter_infra/flutter';

/// Exceptions for known error cases in updating the engine.
class EngineUpdateException implements Exception {
  EngineUpdateException(this.message);

  final String message;
}

/// Simple container for platform-specific information.
class _PlatformInfo {
  _PlatformInfo(this.archiveSubpath, this.libraryFiles);

  /// The subpath on storage.googleapis.com for a platform's engine archive.
  final String archiveSubpath;

  /// The top-level extracted files for a platform.
  ///
  /// The first item in the array is the library itself, and any other items
  /// are supporting files (headers, symbols, etc.).
  final List<String> libraryFiles;
}

/// _PlatformInfo for each supported platform.
final Map<String, _PlatformInfo> _platformInfo = {
  'linux': _PlatformInfo('linux-x64/linux-x64-embedder', [
    'libflutter_engine.so',
    'flutter_embedder.h',
  ]),
  'macos': _PlatformInfo('darwin-x64/FlutterEmbedder.framework.zip', [
    'FlutterEmbedder.framework',
  ]),
  'windows': _PlatformInfo('windows-x64/windows-x64-embedder.zip', [
    'flutter_engine.dll',
    'flutter_engine.dll.exp',
    'flutter_engine.dll.lib',
    'flutter_engine.dll.pdb',
    'flutter_embedder.h',
  ]),
};

/// Manages the downloading of prebuilt Flutter artifacts, including tracking
/// the last downloaded versions and fetching only if necessary.
class FlutterArtifactFetcher {
  /// Creates a new fetcher for the given configuration.
  const FlutterArtifactFetcher(this.platform, this.flutterRoot);

  /// The platform to download artifacts for.
  final String platform;

  /// The path to the root of the Flutter tree to match downloaded artifacts to.
  final String flutterRoot;

  /// Checks [targetDirectory] for an already-downloaded engine with the correct
  /// hash, and if it's either not present or not up-to-date, attempts
  /// to download the prebuilt engine for [platform] with that hash.
  ///
  /// Returns true if the engine was successfully downloaded, or was already
  /// present with the correct hash.
  ///
  /// By default the version to fetch will be based on the provided Flutter
  /// tree's version, but that can overridden by passing an [engineHash].
  ///
  /// In the future, this will take a parameter for the type of artifact to
  /// fetch.
  Future<bool> fetchArtifact(String targetDirectory,
      {String engineHash}) async {
    final targetHash =
        engineHash ?? await engineHashForFlutterTree(flutterRoot);

    try {
      final libraryFile = _platformInfo[platform].libraryFiles[0];

      final currentHash =
          await _lastDownloadedEngineHash(targetDirectory, platform);
      if (currentHash == null || targetHash != currentHash) {
        await _downloadEngine(targetHash, platform, targetDirectory);
        await _setLastDownloadedEngineHash(targetDirectory, targetHash);
        print('Downloaded $libraryFile version $targetHash.');
      } else {
        print('$libraryFile version $targetHash already present.');
      }
    } on EngineUpdateException catch (e) {
      print(e.message);
      return false;
    }
    return true;
  }

  /// Acts like [fetchArtifact], replacing the downloaded artifacts and updating
  /// the version stamp, except that it pulls the artifact from a local engine
  /// build with the given [buildConfiguration] (e.g., host_debug_unopt) whose
  /// checkout is rooted at [engineRoot].
  ///
  /// In the future, this will take a parameter for the type of artifact to
  /// copy.
  Future<bool> copyLocalArtifact(String engineRoot, String targetDirectory,
      String buildConfiguration) async {
    // TODO: Add a warning if the engine tree's HEAD doesn't have
    // engineHashForFlutterTree(flutterRoot) as an ancestor, to catch some
    // mismatches.
    final buildOutputDirectory =
        path.join(engineRoot, 'src', 'out', buildConfiguration);

    try {
      await new Directory(targetDirectory).create(recursive: true);

      // On macOS, delete the existing framework if any before copying in the
      // new one, since it's a directory. On the other platforms, where files
      // are just individual files, this isn't necessary since copying over
      // existing files will do the right thing.
      if (platform == 'macos') {
        await _copyMacOSFramework(
            path.join(
                buildOutputDirectory, _platformInfo[platform].libraryFiles[0]),
            targetDirectory);
      } else {
        for (final filename in _platformInfo[platform].libraryFiles) {
          final sourceFile = File(path.join(buildOutputDirectory, filename));
          await sourceFile.copy(path.join(targetDirectory, filename));
        }
      }

      print('Copied local engine from $buildOutputDirectory.');

      // Update the hash file to indicate that it's a local build, so that it's
      // obvious where it came from.
      await _setLastDownloadedEngineHash(
          targetDirectory, 'local engine: $buildOutputDirectory');
    } on EngineUpdateException catch (e) {
      print(e.message);
      return false;
    }
    return true;
  }

  /// The valid platforms that can be passed to the constructor.
  static List<String> get supportedPlatforms => _platformInfo.keys.toList();

  /// Returns a File object for the file containing the last downloaded engine
  /// hash in [directory].
  File _lastDownloadedHashEngineFile(String directory) {
    const lastDownloadedVersionFile = '.last_engine_version';
    return new File(path.join(directory, lastDownloadedVersionFile));
  }

  /// Returns the last downloaded engine's hash, or null if there is no
  /// last downloaded engine.
  Future<String> _lastDownloadedEngineHash(
      String downloadDirectory, String platform) async {
    final engineFilePath =
        path.join(downloadDirectory, _platformInfo[platform].libraryFiles[0]);
    final engineExists = (FileSystemEntity.typeSync(engineFilePath)) !=
        FileSystemEntityType.notFound;
    if (!engineExists) {
      return null;
    }
    final hashFile = _lastDownloadedHashEngineFile(downloadDirectory);
    return await readHashFileIfPossible(hashFile);
  }

  /// Writes [hash] to the file that stores the last downloaded engine
  /// hash in [directory].
  Future<void> _setLastDownloadedEngineHash(
      String directory, String hash) async {
    await _lastDownloadedHashEngineFile(directory).writeAsString(hash);
  }

  /// Downloads the version of the engine specified by [hash] for [platform] to
  /// the [outputDirectory], extracting and removing the archived version.
  Future<void> _downloadEngine(
      String hash, String platform, String outputDirectory) async {
    final archiveUri = Uri.parse('$_flutterArtifactBaseUrlString/$hash/'
        '${_platformInfo[platform].archiveSubpath}');

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
      await _extractEngineArchive(archiveData, platform, outputDirectory);
    } on ArchiveException catch (e) {
      throw new EngineUpdateException('Unable to extract archive: $e');
    }
  }

  /// Extracts the [archiveData] to [outputDirectory].
  Future<void> _extractEngineArchive(
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
      await _unzipMacOSFramework(innermostZipData, outputDirectory);
    } else {
      // Windows and Linux have flat archives, so can be easily extracted via
      // Archive.
      for (final file in archive) {
        if (file.name.endsWith('.zip')) {
          await _extractEngineArchive(file.content, platform, outputDirectory);
        } else {
          final extractedFile = new File(path.join(outputDirectory, file.name));
          await extractedFile.writeAsBytes(file.content);
        }
      }
    }
  }

  /// Unzips the framework archive [archiveData] in [outputDirectory]
  /// by invoking /usr/bin/unzip.
  ///
  /// Removes any previous version of the framework that already exists there.
  Future<void> _unzipMacOSFramework(
      List<int> archiveData, String outputDirectory) async {
    final temporaryArchiveFile =
        new File(path.join(outputDirectory, 'engine_archive.zip'));
    final targetPath =
        path.join(outputDirectory, _platformInfo['macos'].libraryFiles[0]);

    await _deleteFrameworkIfPresent(targetPath);

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
  Future<void> _copyMacOSFramework(
      String frameworkPath, String targetDirectory) async {
    await _deleteFrameworkIfPresent(
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
  Future<void> _deleteFrameworkIfPresent(String frameworkPath) async {
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
}

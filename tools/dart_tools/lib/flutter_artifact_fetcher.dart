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

// This script copies Flutter engine artifacts from either the Flutter cache or
// a local engine build.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'flutter_utils.dart';

/// The diretory in the Flutter cache for each platform's artifacts.
final _flutterArtifactPlatformDirectory = {
  'linux': 'linux-x64',
  'macos': 'darwin-x64',
  'windows': 'windows-x64',
};

/// Exceptions for known error cases in fetching artifacts.
class FlutterArtifactFetchException implements Exception {
  FlutterArtifactFetchException(this.message);

  final String message;
}

/// The list of artifacts relevant to building for each desktop platform.
final Map<String, List<String>> _artifactFiles = {
  'linux': [
    'libflutter_linux.so',
    'flutter_export.h',
    'flutter_messenger.h',
    'flutter_plugin_registrar.h',
    'flutter_glfw.h',
    'cpp_client_wrapper/',
  ],
  'macos': [
    'FlutterMacOS.framework',
  ],
  'windows': [
    'flutter_windows.dll',
    'flutter_windows.dll.exp',
    'flutter_windows.dll.lib',
    'flutter_windows.dll.pdb',
    'flutter_export.h',
    'flutter_messenger.h',
    'flutter_plugin_registrar.h',
    'flutter_glfw.h',
    'cpp_client_wrapper/',
  ],
};

/// Manages the copying of cached or locally built Flutter artifacts, including
/// tracking the last-coied versions and updating only if necessary.
class FlutterArtifactFetcher {
  /// Creates a new fetcher for the given configuration.
  const FlutterArtifactFetcher(this.platform, this.flutterRoot);

  /// The platform to copy artifacts for.
  final String platform;

  /// The path to the root of the Flutter tree.
  final String flutterRoot;

  /// Checks [targetDirectory] to see if artifacts have already been copied for
  /// the current hash, and if not, copies the artifacts for [platform] from the
  /// Flutter cache (after ensuring that the cache is present).
  ///
  /// Returns true if the artifacts were successfully copied, or were already
  /// present with the correct hash.
  Future<bool> copyCachedArtifacts(String targetDirectory) async {
    final targetHash = await engineHashForFlutterTree(flutterRoot);

    try {
      final currentHash = await _lastCopiedHash(targetDirectory);
      if (currentHash == null || targetHash != currentHash) {
        // Ensure that Flutter has the host platform's artifacts in its cache.
        await runFlutterCommand(flutterRoot,
            ['precache', '--$platform', '--no-android', '--no-ios']);

        // Copy them to the target directory.
        final flutterCacheDirectory = path.join(flutterRoot, 'bin', 'cache',
            'artifacts', 'engine', _flutterArtifactPlatformDirectory[platform]);
        if (!await _copyArtifactFiles(flutterCacheDirectory, targetDirectory)) {
          return false;
        }
        await _setLastCopiedHash(targetDirectory, targetHash);
        print('Copied artifacts for version $targetHash.');
      } else {
        print('Artifacts for version $targetHash already present.');
      }
    } on FlutterArtifactFetchException catch (e) {
      print(e.message);
      return false;
    }
    return true;
  }

  /// Acts like [copyCachedArtifacts], replacing the artifacts and updating
  /// the version stamp, except that it pulls the artifact from a local engine
  /// build with the given [buildConfiguration] (e.g., host_debug_unopt) whose
  /// checkout is rooted at [engineRoot].
  Future<bool> copyLocalBuildArtifacts(String engineRoot,
      String targetDirectory, String buildConfiguration) async {
    // TODO: Add a warning if the engine tree's HEAD doesn't have
    // engineHashForFlutterTree(flutterRoot) as an ancestor, to catch some
    // mismatches.
    final buildOutputDirectory =
        path.join(engineRoot, 'src', 'out', buildConfiguration);

    if (!await _copyArtifactFiles(buildOutputDirectory, targetDirectory)) {
      return false;
    }

    // Update the hash file to indicate that it's a local build, so that it's
    // obvious where it came from.
    await _setLastCopiedHash(
        targetDirectory, 'local build: $buildOutputDirectory');

    return true;
  }

  /// Copies the artifact files for [platform] from [sourceDirectory] to
  /// [targetDirectory].
  Future<bool> _copyArtifactFiles(
      String sourceDirectory, String targetDirectory) async {
    final artifactFiles = _artifactFiles[platform];
    if (artifactFiles == null) {
      print('Unsupported platform: $platform.');
      return false;
    }

    try {
      await new Directory(targetDirectory).create(recursive: true);

      // On macOS, delete the existing framework if any before copying in the
      // new one, since it's a directory. On the other platforms, where files
      // are just individual files, this isn't necessary since copying over
      // existing files will do the right thing.
      if (platform == 'macos') {
        await _copyMacOSFramework(
            path.join(sourceDirectory, artifactFiles[0]), targetDirectory);
      } else {
        for (final filename in artifactFiles) {
          final sourcePath = path.join(sourceDirectory, filename);
          final targetPath = path.join(targetDirectory, filename);
          if (filename.endsWith('/')) {
            await _copyDirectory(sourcePath, targetPath);
          } else {
            await File(sourcePath).copy(path.join(targetDirectory, filename));
          }
        }
      }

      print('Copied artifacts from $sourceDirectory.');
    } on FlutterArtifactFetchException catch (e) {
      print(e.message);
      return false;
    }
    return true;
  }

  /// The valid platforms that can be passed to the constructor.
  static List<String> get supportedPlatforms => _artifactFiles.keys.toList();

  /// Returns a File object for the file containing the last copied hash
  /// in [directory].
  File _lastCopiedHashFile(String directory) {
    const lastCopiedVersionFile = '.last_artifact_version';
    return new File(path.join(directory, lastCopiedVersionFile));
  }

  /// Returns the hash of the artifacts last copied to [directory], or null if
  /// they haven't been copied.
  Future<String> _lastCopiedHash(String directory) async {
    // Sanity check that at least one file is present; this won't catch every
    // case, but handles someone deleting all the non-hidden cached files to
    // force fresh copy.
    final artifactFilePath = path.join(directory, _artifactFiles[platform][0]);
    final artifactExists = (FileSystemEntity.typeSync(artifactFilePath)) !=
        FileSystemEntityType.notFound;
    if (!artifactExists) {
      return null;
    }
    final hashFile = _lastCopiedHashFile(directory);
    return await readHashFileIfPossible(hashFile);
  }

  /// Writes [hash] to the file that stores the last copied hash for
  /// in [directory].
  Future<void> _setLastCopiedHash(String directory, String hash) async {
    await _lastCopiedHashFile(directory).writeAsString(hash);
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
      throw new FlutterArtifactFetchException(
          'Failed to copy framework (exit ${result.exitCode}:\n'
          '${result.stdout}\n---\n${result.stderr}');
    }
  }

  /// Recursively deletes the framework at [frameworkPath], if it exists.
  Future<void> _deleteFrameworkIfPresent(String frameworkPath) async {
    // Ensure that the path is a framework, to minimize the potential for
    // catastrophic deletion bugs with bad arguments.
    if (path.extension(frameworkPath) != '.framework') {
      throw new FlutterArtifactFetchException(
          'Attempted to delete a non-framework directory: $frameworkPath');
    }

    final directory = new Directory(frameworkPath);
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  }

  /// Copies the directory at [sourcePath] into [targetPath], recursively.
  Future<void> _copyDirectory(String sourcePath, String targetPath) async {
    final source = Directory(sourcePath);
    if (!source.existsSync()) {
      throw new FlutterArtifactFetchException(
          'No such directory to copy: $sourcePath');
    }
    Directory(targetPath).createSync();
    await for (final file in source.list(followLinks: false)) {
      final filename = path.basename(file.path);
      final fileDestination = path.join(targetPath, filename);
      if (file is File) {
        await file.copy(fileDestination);
      } else if (file is Directory) {
        await _copyDirectory(file.path, fileDestination);
      } else {
        throw new FlutterArtifactFetchException(
            'Unhandled file type while copying: ${file.path}');
      }
    }
  }
}

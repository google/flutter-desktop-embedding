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

/// Types of Flutter artifacts that can be copied.
enum FlutterArtifactType {
  /// The Flutter library.
  flutter,

  /// The C++ wrapper code.
  wrapper,
}

/// Returns the name that should be shown to users for [type].
String _displayNameForArtifactType(FlutterArtifactType type) {
  return type.toString().split('.').last;
}

/// Simple container for platform- and artifact-specific information.
class _ArtifactDetails {
  _ArtifactDetails(this.artifactFilename, this.libraryFiles);

  /// The filename on storage.googleapis.com under the platform directory for
  /// the artifact.
  final String artifactFilename;

  /// The top-level extracted files for a platform.
  ///
  /// The first item in the array is the library itself, and any other items
  /// are supporting files (headers, symbols, etc.).
  final List<String> libraryFiles;
}

/// _ArtifactDetails for each supported platform.
final Map<String, Map<FlutterArtifactType, _ArtifactDetails>> _artifactDetails =
    {
  'linux': {
    FlutterArtifactType.flutter: _ArtifactDetails('linux-x64-flutter.zip', [
      'libflutter_linux.so',
      'flutter_export.h',
      'flutter_messenger.h',
      'flutter_plugin_registrar.h',
      'flutter_glfw.h',
    ]),
    FlutterArtifactType.wrapper:
        _ArtifactDetails('flutter-cpp-client-wrapper.zip', [
      'cpp_client_wrapper/',
    ])
  },
  'macos': {
    FlutterArtifactType.flutter:
        _ArtifactDetails('FlutterMacOS.framework.zip', [
      'FlutterMacOS.framework',
    ])
  },
  'windows': {
    FlutterArtifactType.flutter: _ArtifactDetails('windows-x64-flutter.zip', [
      'flutter_windows.dll',
      'flutter_windows.dll.exp',
      'flutter_windows.dll.lib',
      'flutter_windows.dll.pdb',
      'flutter_export.h',
      'flutter_messenger.h',
      'flutter_plugin_registrar.h',
      'flutter_glfw.h',
    ]),
    FlutterArtifactType.wrapper:
        _ArtifactDetails('flutter-cpp-client-wrapper.zip', [
      'cpp_client_wrapper/',
    ])
  },
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
  /// the current hash, and if not, copies [artifact] for [platform] from the
  /// Flutter cache (after ensuring that the cache is present).
  ///
  /// Returns true if the artifacts were successfully copied, or were already
  /// present with the correct hash.
  Future<bool> copyCachedArtifacts(
      FlutterArtifactType artifact, String targetDirectory) async {
    final artifactDetails = _artifactDetails[platform][artifact];
    if (artifactDetails == null) {
      print('Artifact type "${_displayNameForArtifactType(artifact)}" is not '
          'yet supported for $platform.');
      return false;
    }

    final targetHash = await engineHashForFlutterTree(flutterRoot);

    try {
      final primaryFile = _artifactDetails[platform][artifact].libraryFiles[0];

      final currentHash = await _lastCopiedHash(artifact, targetDirectory);
      if (currentHash == null || targetHash != currentHash) {
        // Ensure that Flutter has the host platform's artifacts in its cache.
        await runFlutterCommand(flutterRoot,
            ['precache', '--$platform', '--no-android', '--no-ios']);

        // Copy them to the target directory.
        final flutterCacheDirectory = path.join(
            flutterRoot,
            'bin',
            'cache',
            'artifacts',
            'engine',
            _flutterArtifactPlatformDirectory[platform]);
        if (!await _copyArtifactFiles(
            artifact, flutterCacheDirectory, targetDirectory)) {
          return false;
        }
        await _setLastCopiedHash(artifact, targetDirectory, targetHash);
        print('Copied $primaryFile version $targetHash.');
      } else {
        print('$primaryFile version $targetHash already present.');
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
  Future<bool> copyLocalBuildArtifacts(
      FlutterArtifactType artifact,
      String engineRoot,
      String targetDirectory,
      String buildConfiguration) async {
    final artifactDetails = _artifactDetails[platform][artifact];
    if (artifactDetails == null) {
      print('${_displayNameForArtifactType(artifact)} is not yet supported '
          'for $platform.');
      return false;
    }

    // TODO: Add a warning if the engine tree's HEAD doesn't have
    // engineHashForFlutterTree(flutterRoot) as an ancestor, to catch some
    // mismatches.
    final buildOutputDirectory =
        path.join(engineRoot, 'src', 'out', buildConfiguration);

    if (!await _copyArtifactFiles(
        artifact, buildOutputDirectory, targetDirectory)) {
      return false;
    }

    // Update the hash file to indicate that it's a local build, so that it's
    // obvious where it came from.
    await _setLastCopiedHash(
        artifact, targetDirectory, 'local build: $buildOutputDirectory');

    return true;
  }

  /// Copies the files listed in [artifact] from [sourceDirectory] to
  /// [targetDirectory].
  Future<bool> _copyArtifactFiles(
      FlutterArtifactType artifact,
      String sourceDirectory,
      String targetDirectory) async {
    final artifactDetails = _artifactDetails[platform][artifact];
    if (artifactDetails == null) {
      print('${_displayNameForArtifactType(artifact)} is not yet supported '
          'for $platform.');
      return false;
    }

    try {
      final artifactDetails = _artifactDetails[platform][artifact];
      await new Directory(targetDirectory).create(recursive: true);

      // On macOS, delete the existing framework if any before copying in the
      // new one, since it's a directory. On the other platforms, where files
      // are just individual files, this isn't necessary since copying over
      // existing files will do the right thing.
      if (platform == 'macos') {
        await _copyMacOSFramework(
            path.join(sourceDirectory, artifactDetails.libraryFiles[0]),
            targetDirectory);
      } else {
        for (final filename in artifactDetails.libraryFiles) {
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
  static List<String> get supportedPlatforms => _artifactDetails.keys.toList();

  /// Returns a File object for the file containing the last copied hash
  /// for [artifact] in [directory].
  File _lastCopiedHashFile(FlutterArtifactType artifact, String directory) {
    final typeString = _displayNameForArtifactType(artifact);
    final lastCopiedVersionFile = '.last_${typeString}_version';
    return new File(path.join(directory, lastCopiedVersionFile));
  }

  /// Returns the hash of the last copied [artifact]s in [directory], or null if there is no
  /// last copied artifact of that type.
  Future<String> _lastCopiedHash(
      FlutterArtifactType artifact, String directory) async {
    final artifactFilePath = path.join(directory,
        _artifactDetails[platform][artifact].libraryFiles[0]);
    final artifactExists = (FileSystemEntity.typeSync(artifactFilePath)) !=
        FileSystemEntityType.notFound;
    if (!artifactExists) {
      return null;
    }
    final hashFile = _lastCopiedHashFile(artifact, directory);
    return await readHashFileIfPossible(hashFile);
  }

  /// Writes [hash] to the file that stores the last copied hash for
  /// [artifact] in [directory].
  Future<void> _setLastCopiedHash(
      FlutterArtifactType artifact, String directory, String hash) async {
    await _lastCopiedHashFile(artifact, directory).writeAsString(hash);
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

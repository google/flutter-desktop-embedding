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

// This script downloads a specific version of a prebuilt Flutter artifact
// for a desktop platform.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';

import 'flutter_utils.dart';

/// The base URL for downloading prebuilt artifacts.
const String _flutterArtifactBaseUrlString =
    'https://storage.googleapis.com/flutter_infra/flutter';

/// The diretory under [_flutterArtifactBaseUrlString] for each platoform's
/// artifacts.
final _flutterArtifactUrlPlatformDirectory = {
  'linux': 'linux-x64',
  'macos': 'darwin-x64',
  'windows': 'windows-x64',
};

/// Exceptions for known error cases in fetching artifacts.
class FlutterArtifactFetchException implements Exception {
  FlutterArtifactFetchException(this.message);

  final String message;
}

/// Types of Flutter artifacts that can be download.
enum FlutterArtifactType {
  /// The engine embedder library.
  engine,

  /// The full Flutter library, including both the engine and the shell.
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
    FlutterArtifactType.engine: _ArtifactDetails('linux-x64-embedder', [
      'libflutter_engine.so',
      'flutter_embedder.h',
    ]),
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
    FlutterArtifactType.engine:
        _ArtifactDetails('FlutterEmbedder.framework.zip', [
      'FlutterEmbedder.framework',
    ]),
    FlutterArtifactType.flutter:
        _ArtifactDetails('FlutterMacOS.framework.zip', [
      'FlutterMacOS.framework',
    ])
  },
  'windows': {
    FlutterArtifactType.engine: _ArtifactDetails('windows-x64-embedder.zip', [
      'flutter_engine.dll',
      'flutter_engine.dll.exp',
      'flutter_engine.dll.lib',
      'flutter_engine.dll.pdb',
      'flutter_embedder.h',
    ]),
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

/// Manages the downloading of prebuilt Flutter artifacts, including tracking
/// the last downloaded versions and fetching only if necessary.
class FlutterArtifactFetcher {
  /// Creates a new fetcher for the given configuration.
  const FlutterArtifactFetcher(this.platform, this.flutterRoot);

  /// The platform to download artifacts for.
  final String platform;

  /// The path to the root of the Flutter tree to match downloaded artifacts to.
  final String flutterRoot;

  /// Checks [targetDirectory] for an already-downloaded [artifact] with the
  /// correct hash, and if it's either not present or not up-to-date, attempts
  /// to download [artifact] for [platform] with that hash.
  ///
  /// Returns true if the artifact was successfully downloaded, or was already
  /// present with the correct hash.
  ///
  /// By default the version to fetch will be based on the provided Flutter
  /// tree's version, but that can overridden by passing an [engineHash].
  ///
  /// In the future, this will take a parameter for the type of artifact to
  /// fetch.
  Future<bool> fetchArtifact(
      FlutterArtifactType artifact, String targetDirectory,
      {String engineHash}) async {
    final artifactDetails = _artifactDetails[platform][artifact];
    if (artifactDetails == null) {
      print('Artifact type "${_displayNameForArtifactType(artifact)}" is not '
          'yet supported for $platform.');
      return false;
    }

    final targetHash =
        engineHash ?? await engineHashForFlutterTree(flutterRoot);

    try {
      final primaryFile = _artifactDetails[platform][artifact].libraryFiles[0];

      final currentHash = await _lastDownloadedHash(artifact, targetDirectory);
      if (currentHash == null || targetHash != currentHash) {
        await _downloadArtifact(artifact, targetHash, targetDirectory);
        await _setLastDownloadedHash(artifact, targetDirectory, targetHash);
        print('Downloaded $primaryFile version $targetHash.');
      } else {
        print('$primaryFile version $targetHash already present.');
      }
    } on FlutterArtifactFetchException catch (e) {
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
  Future<bool> copyLocalArtifact(
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

    try {
      final artifactDetails = _artifactDetails[platform][artifact];
      await new Directory(targetDirectory).create(recursive: true);

      // On macOS, delete the existing framework if any before copying in the
      // new one, since it's a directory. On the other platforms, where files
      // are just individual files, this isn't necessary since copying over
      // existing files will do the right thing.
      if (platform == 'macos') {
        await _copyMacOSFramework(
            path.join(buildOutputDirectory, artifactDetails.libraryFiles[0]),
            targetDirectory);
      } else {
        for (final filename in artifactDetails.libraryFiles) {
          final sourcePath = path.join(buildOutputDirectory, filename);
          final targetPath = path.join(targetDirectory, filename);
          if (filename.endsWith('/')) {
            await _copyDirectory(sourcePath, targetPath);
          } else {
            await File(sourcePath).copy(path.join(targetDirectory, filename));
          }
        }
      }

      print('Copied local artifact from $buildOutputDirectory.');

      // Update the hash file to indicate that it's a local build, so that it's
      // obvious where it came from.
      await _setLastDownloadedHash(
          artifact, targetDirectory, 'local artifact: $buildOutputDirectory');
    } on FlutterArtifactFetchException catch (e) {
      print(e.message);
      return false;
    }
    return true;
  }

  /// The valid platforms that can be passed to the constructor.
  static List<String> get supportedPlatforms => _artifactDetails.keys.toList();

  /// Returns a File object for the file containing the last downloaded hash
  /// for [artifact] in [directory].
  File _lastDownloadedHashFile(FlutterArtifactType artifact, String directory) {
    final typeString = _displayNameForArtifactType(artifact);
    final lastDownloadedVersionFile = '.last_${typeString}_version';
    return new File(path.join(directory, lastDownloadedVersionFile));
  }

  /// Returns the last downloaded [artifact]'s hash, or null if there is no
  /// last downloaded artifact of that type.
  Future<String> _lastDownloadedHash(
      FlutterArtifactType artifact, String downloadDirectory) async {
    final artifactFilePath = path.join(downloadDirectory,
        _artifactDetails[platform][artifact].libraryFiles[0]);
    final artifactExists = (FileSystemEntity.typeSync(artifactFilePath)) !=
        FileSystemEntityType.notFound;
    if (!artifactExists) {
      return null;
    }
    final hashFile = _lastDownloadedHashFile(artifact, downloadDirectory);
    return await readHashFileIfPossible(hashFile);
  }

  /// Writes [hash] to the file that stores the last downloaded hash for
  /// [artifact] in [directory].
  Future<void> _setLastDownloadedHash(
      FlutterArtifactType artifact, String directory, String hash) async {
    await _lastDownloadedHashFile(artifact, directory).writeAsString(hash);
  }

  /// Downloads the version of [artifact] specified by [hash] for [platform] to
  /// the [outputDirectory], extracting and removing the archived version.
  Future<void> _downloadArtifact(
      FlutterArtifactType artifact, String hash, String outputDirectory) async {
    final archiveUri = Uri.parse('$_flutterArtifactBaseUrlString/$hash/'
        '${_flutterArtifactUrlPlatformDirectory[platform]}/'
        '${_artifactDetails[platform][artifact].artifactFilename}');

    final httpClient = new HttpClient();
    final response =
        await httpClient.getUrl(archiveUri).then((request) => request.close());
    final archiveData = <int>[];
    await for (final data in response) {
      archiveData.addAll(data);
    }
    httpClient.close();
    if (archiveData.length < 500) {
      final artifactName = _displayNameForArtifactType(artifact);
      throw new FlutterArtifactFetchException(
          'Artifact "$artifactName" is not available at $hash.');
    }
    try {
      await _extractArchive(artifact, archiveData, outputDirectory);
    } on ArchiveException catch (e) {
      throw new FlutterArtifactFetchException('Unable to extract archive: $e');
    }
  }

  /// Extracts the [archiveData] to [outputDirectory].
  Future<void> _extractArchive(FlutterArtifactType artifact,
      List<int> archiveData, String outputDirectory) async {
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
      await _unzipMacOSFramework(innermostZipData, outputDirectory,
          _artifactDetails[platform][artifact].libraryFiles[0]);
    } else {
      // Windows and Linux have simple archives, so can be easily extracted via
      // Archive.
      for (final file in archive) {
        if (file.name.endsWith('.zip')) {
          await _extractArchive(artifact, file.content, outputDirectory);
        } else {
          final outputPath = path.join(outputDirectory, file.name);
          if (file.isFile) {
            // The archive does not contain directory entries on Windows, so
            // always ensure the directory for the target exists first.
            await Directory(path.dirname(outputPath)).create(recursive: true);
            await File(outputPath).writeAsBytes(file.content);
          } else {
            await Directory(outputPath).create(recursive: true);
          }
        }
      }
    }
  }

  /// Unzips the framework archive [archiveData] in [outputDirectory]
  /// by invoking /usr/bin/unzip.
  ///
  /// Removes any previous version of the framework that already exists there.
  Future<void> _unzipMacOSFramework(List<int> archiveData,
      String outputDirectory, String frameworkFilename) async {
    final temporaryArchiveFile =
        new File(path.join(outputDirectory, 'artifact_archive.zip'));
    final targetPath = path.join(outputDirectory, frameworkFilename);

    await _deleteFrameworkIfPresent(targetPath);

    // Temporarily write the data to a file, since unzip doesn't accept piped
    // input, then delete the file.
    await temporaryArchiveFile.writeAsBytes(archiveData);
    final result = await Process.run(
        '/usr/bin/unzip', [temporaryArchiveFile.path, '-d', targetPath]);
    await temporaryArchiveFile.delete();
    if (result.exitCode != 0) {
      throw new FlutterArtifactFetchException(
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
    final destination = Directory(targetPath)..createSync();
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

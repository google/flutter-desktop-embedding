import 'dart:io' as io;

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';

/**
 * Print the entries in the given tar file.
 */
void listFiles(String path) {
  io.File file = new io.File(path);
  if (!file.existsSync()) fail('${path} does not exist');

  List<int> data = file.readAsBytesSync();
  if (path.endsWith('tar.gz') || path.endsWith('tgz')) {
    data = new GZipDecoder().decodeBytes(data);
  } else if (path.endsWith('tar.bz2') || path.endsWith('tbz')) {
    data = new BZip2Decoder().decodeBytes(data);
  }

  TarDecoder tarArchive = new TarDecoder();
  // Tell the decoder not to store the actual file data since we don't need
  // it.
  tarArchive.decodeBytes(data, storeData: false);

  print('${tarArchive.files.length} file(s)');
  tarArchive.files.forEach((f) => print('  ${f}'));
}

/**
 * Extract the entries in the given tar file to a directory.
 */
io.Directory extractFiles(String inputPath, String outputPath) {
  io.Directory temp_dir;
  String tar_path = inputPath;

  if (inputPath.endsWith('tar.gz') || inputPath.endsWith('tgz')) {
    temp_dir = io.Directory.systemTemp.createTempSync('dart_archive');
    tar_path = '${temp_dir.path}${io.Platform.pathSeparator}temp.tar';
    InputFileStream input = new InputFileStream(inputPath);
    OutputFileStream output = new OutputFileStream(tar_path);
    new GZipDecoder().decodeStream(input, output);
    input.close();
    output.close();
  }

  io.Directory outDir = new io.Directory(outputPath);
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  InputFileStream input = new InputFileStream(tar_path);

  TarDecoder tarArchive = new TarDecoder()..decodeBuffer(input);

  for (TarFile file in tarArchive.files) {
    if (!file.isFile) {
      continue;
    }
    io.File f = new io.File(
        '${outputPath}${io.Platform.pathSeparator}${file.filename}');
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(file.content);
    print('  extracted ${file.filename}');
  };

  input.close();

  if (temp_dir != null) {
    temp_dir.delete(recursive: true);
  }

  /*io.File inputFile = new io.File(inputPath);
  if (!inputFile.existsSync()) fail('${inputPath} does not exist');

  io.Directory outDir = new io.Directory(outputPath);
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  List<int> data = inputFile.readAsBytesSync();
  if (inputPath.endsWith('tar.gz') || inputPath.endsWith('tgz')) {
    data = new GZipDecoder().decodeBytes(data);
  } else if (inputPath.endsWith('tar.bz2') || inputPath.endsWith('tbz')) {
    data = new BZip2Decoder().decodeBytes(data);
  }

  TarDecoder tarArchive = new TarDecoder();
  tarArchive.decodeBytes(data);*

  print('extracting to ${outDir.path}${io.Platform.pathSeparator}...');

  for (TarFile file in tarArchive.files) {
    if (!file.isFile) {
      continue;
    }
    io.File f = new io.File(
        '${outputPath}${io.Platform.pathSeparator}${file.filename}');
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(file.content);
    print('  extracted ${file.filename}');
  };*/

  return outDir;
}

void createTarFile(String dirPath) {
  io.Directory dir = new io.Directory(dirPath);
  if (!dir.existsSync()) fail('${dirPath} does not exist');

  // Encode a directory from disk to disk, no memory
  TarFileEncoder encoder = new TarFileEncoder();
  encoder.tarDirectory(dir, compression: TarFileEncoder.GZIP);
}

void fail(String message) {
  print(message);
  io.exit(1);
}

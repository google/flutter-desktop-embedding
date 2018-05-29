part of archive_io;


class TarFileEncoder {
  String tar_path;
  OutputFileStream _output;
  TarEncoder _encoder;

  static const int STORE = 0;
  static const int GZIP = 1;

  void tarDirectory(io.Directory dir, {int compression: STORE,
                    String filename}) {
    String dirPath = dir.path;
    String tar_path = filename != null ? filename : '${dirPath}.tar';
    String tgz_path = filename != null ? filename : '${dirPath}.tar.gz';

    io.Directory temp_dir;
    if (compression == GZIP) {
      temp_dir = io.Directory.systemTemp.createTempSync('dart_archive');
      tar_path = temp_dir.path + '/temp.tar';
    }

    // Encode a directory from disk to disk, no memory
    open(tar_path);
    addDirectory(new io.Directory(dirPath));
    close();

    if (compression == GZIP) {
      InputFileStream input = new InputFileStream(tar_path);
      OutputFileStream output = new OutputFileStream(tgz_path);
      new GZipEncoder()..encode(input, output: output);
      input.close();
      new io.File(input.path).deleteSync();
    }
  }

  void open(String tar_path) {
    this.tar_path = tar_path;
    _output = new OutputFileStream(tar_path);
    _encoder = new TarEncoder();
    _encoder.start(_output);
  }

  void addDirectory(io.Directory dir) {
    List files = dir.listSync(recursive:true);

    for (var fe in files) {
      if (fe is! io.File) {
        continue;
      }

      io.File f = fe as io.File;
      String rel_path = path.relative(f.path, from: dir.path);
      addFile(f, rel_path);
    }
  }

  void addFile(io.File file, [String filename]) {
    InputFileStream file_stream = new InputFileStream.file(file);
    ArchiveFile f = new ArchiveFile.stream(filename == null ? file.path : filename,
        file.lengthSync(), file_stream);
    f.lastModTime = file.lastModifiedSync().millisecondsSinceEpoch;
    f.mode = file.statSync().mode;
    _encoder.add(f);
    file_stream.close();
  }

  void close() {
    _encoder.finish();
    _output.close();
  }
}
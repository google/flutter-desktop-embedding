part of archive;

/**
 * Encode an [Archive] object into a tar formatted buffer.
 */
class TarEncoder {
  List<int> encode(Archive archive) {
    OutputStream output_stream = new OutputStream();
    start(output_stream);

    for (ArchiveFile file in archive.files) {
      add(file);
    }

    finish();

    return output_stream.getBytes();
  }

  void start([dynamic output_stream]) {
    _output_stream = output_stream != null ? output_stream : new OutputStream();
  }

  void add(ArchiveFile file) {
    if (_output_stream == null) {
      return;
    }
    TarFile ts = new TarFile();
    ts.filename = file.name;
    ts.fileSize = file.size;
    ts.mode = file.mode;
    ts.ownerId = file.ownerId;
    ts.groupId = file.groupId;
    ts.lastModTime = file.lastModTime;
    ts._content = file.content;
    ts.write(_output_stream);
  }

  void finish() {
    // At the end of the archive file there are two 512-byte blocks filled
    // with binary zeros as an end-of-file marker.
    Uint8List eof = new Uint8List(1024);
    _output_stream.writeBytes(eof);
    _output_stream = null;
  }

  dynamic _output_stream;
}

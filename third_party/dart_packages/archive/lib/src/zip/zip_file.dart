part of archive;

class ZipFile {
  static const int STORE = 0;
  static const int DEFLATE = 8;
  static const int BZIP2 = 12;

  static const int SIGNATURE = 0x04034b50;

  int signature = SIGNATURE; // 4 bytes
  int version = 0; // 2 bytes
  int flags = 0; // 2 bytes
  int compressionMethod = 0; // 2 bytes
  int lastModFileTime = 0; // 2 bytes
  int lastModFileDate = 0; // 2 bytes
  int crc32; // 4 bytes
  int compressedSize; // 4 bytes
  int uncompressedSize; // 4 bytes
  String filename = ''; // 2 bytes length, n-bytes data
  List<int> extraField = []; // 2 bytes length, n-bytes data
  ZipFileHeader header;

  ZipFile([InputStream input, this.header]) {
    if (input != null) {
      signature = input.readUint32();
      if (signature != SIGNATURE) {
        throw new ArchiveException('Invalid Zip Signature');
      }

      version = input.readUint16();
      flags = input.readUint16();
      compressionMethod = input.readUint16();
      lastModFileTime = input.readUint16();
      lastModFileDate = input.readUint16();
      crc32 = input.readUint32();
      compressedSize = input.readUint32();
      uncompressedSize = input.readUint32();
      int fn_len = input.readUint16();
      int ex_len = input.readUint16();
      filename = input.readString(fn_len);
      extraField = input.readBytes(ex_len).toUint8List();

      // Read compressedSize bytes for the compressed data.
      _rawContent = input.readBytes(header.compressedSize);

      // If bit 3 (0x08) of the flags field is set, then the CRC-32 and file
      // sizes are not known when the header is written. The fields in the
      // local header are filled with zero, and the CRC-32 and size are
      // appended in a 12-byte structure (optionally preceded by a 4-byte
      // signature) immediately after the compressed data:
      if (flags & 0x08 != 0) {
        int sigOrCrc = input.readUint32();
        if (sigOrCrc == 0x08074b50) {
          crc32 = input.readUint32();
        } else {
          crc32 = sigOrCrc;
        }

        compressedSize = input.readUint32();
        uncompressedSize = input.readUint32();
      }
    }
  }

  /**
   * This will decompress the data (if necessary) in order to calculate the
   * crc32 checksum for the decompressed data and verify it with the value
   * stored in the zip.
   */
  bool verifyCrc32() {
    if (_computedCrc32 == null) {
      _computedCrc32 = getCrc32(content);
    }
    return _computedCrc32 == crc32;
  }

  /**
   * Get the decompressed content from the file.  The file isn't decompressed
   * until it is requested.
   */
  List<int> get content {
    if (_content == null) {
      if (compressionMethod == DEFLATE) {
        _content = new Inflate.buffer(_rawContent, uncompressedSize).getBytes();
        compressionMethod = STORE;
      } else {
        _content = _rawContent.toUint8List();
      }
    }
    return _content;
  }

  String toString() => filename;

  /// Content of the file.  If compressionMethod is not STORE, then it is
  /// still compressed.
  InputStream _rawContent;
  List<int> _content;
  int _computedCrc32;
}

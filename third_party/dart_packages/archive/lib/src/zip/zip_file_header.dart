part of archive;

class ZipFileHeader {
  static const int SIGNATURE = 0x02014b50;
  int versionMadeBy = 0; // 2 bytes
  int versionNeededToExtract = 0; // 2 bytes
  int generalPurposeBitFlag = 0; // 2 bytes
  int compressionMethod = 0; // 2 bytes
  int lastModifiedFileTime = 0; // 2 bytes
  int lastModifiedFileDate = 0; // 2 bytes
  int crc32; // 4 bytes
  int compressedSize; // 4 bytes
  int uncompressedSize; // 4 bytes
  int diskNumberStart; // 2 bytes
  int internalFileAttributes; // 2 bytes
  int externalFileAttributes; // 4 bytes
  int localHeaderOffset; // 4 bytes
  String filename = '';
  List<int> extraField = [];
  String fileComment = '';
  ZipFile file;

  ZipFileHeader([InputStream input, InputStream bytes]) {
    if (input != null) {
      versionMadeBy = input.readUint16();
      versionNeededToExtract = input.readUint16();
      generalPurposeBitFlag = input.readUint16();
      compressionMethod = input.readUint16();
      lastModifiedFileTime = input.readUint16();
      lastModifiedFileDate = input.readUint16();
      crc32 = input.readUint32();
      compressedSize = input.readUint32();
      uncompressedSize = input.readUint32();
      int fname_len = input.readUint16();
      int extra_len = input.readUint16();
      int comment_len = input.readUint16();
      diskNumberStart = input.readUint16();
      internalFileAttributes = input.readUint16();
      externalFileAttributes = input.readUint32();
      localHeaderOffset = input.readUint32();

      if (fname_len > 0) {
        filename = input.readString(fname_len);
      }

      if (extra_len > 0) {
        InputStream extra = input.readBytes(extra_len);
        extraField = extra.toUint8List();

        int id = extra.readUint16();
        int size = extra.readUint16();
        if (id == 1) {
          // Zip64 extended information
          // Original
          // Size       8 bytes    Original uncompressed file size
          // Compressed
          // Size       8 bytes    Size of compressed data
          // Relative Header
          // Offset     8 bytes    Offset of local header record
          // Disk Start
          // Number     4 bytes    Number of the disk on which
          // this file starts
          if (size >= 8) {
            uncompressedSize = extra.readUint64();
          }
          if (size >= 16) {
            compressedSize = extra.readUint64();
          }
          if (size >= 24) {
            localHeaderOffset = extra.readUint64();
          }
          if (size >= 28) {
            diskNumberStart = extra.readUint32();
          }
        }
      }

      if (comment_len > 0) {
        fileComment = input.readString(comment_len);
      }

      if (bytes != null) {
        bytes.offset = localHeaderOffset;
        file = new ZipFile(bytes, this);
      }
    }
  }

  String toString() => filename;
}

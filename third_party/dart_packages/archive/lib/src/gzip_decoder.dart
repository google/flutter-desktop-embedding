part of archive;

/**
 * Decompress data with the gzip format decoder.
 */
class GZipDecoder {
  static const int SIGNATURE = 0x8b1f;
  static const int DEFLATE = 8;
  static const int FLAG_TEXT = 0x01;
  static const int FLAG_HCRC = 0x02;
  static const int FLAG_EXTRA = 0x04;
  static const int FLAG_NAME = 0x08;
  static const int FLAG_COMMENT = 0x10;

  List<int> decodeBytes(List<int> data, {bool verify: false}) {
    return decodeBuffer(new InputStream(data), verify: verify);
  }

  void decodeStream(dynamic input, dynamic output) {
    _readHeader(input);
    new Inflate.stream(input, output);
  }

  List<int> decodeBuffer(dynamic input, {bool verify: false}) {
    _readHeader(input);

    // Inflate
    List<int> buffer = new Inflate.buffer(input).getBytes();

    if (verify) {
      int crc = input.readUint32();
      int computedCrc = getCrc32(buffer);
      if (crc != computedCrc) {
        throw new ArchiveException('Invalid CRC checksum');
      }

      int size = input.readUint32();
      if (size != buffer.length) {
        throw new ArchiveException('Size of decompressed file not correct');
      }
    }

    return buffer;
  }

  void _readHeader(dynamic input) {
    // The GZip format has the following structure:
    // Offset   Length   Contents
    // 0      2 bytes  magic header  0x1f, 0x8b (\037 \213)
    // 2      1 byte   compression method
    //                  0: store (copied)
    //                  1: compress
    //                  2: pack
    //                  3: lzh
    //                  4..7: reserved
    //                  8: deflate
    // 3      1 byte   flags
    //                  bit 0 set: file probably ascii text
    //                  bit 1 set: continuation of multi-part gzip file, part number present
    //                  bit 2 set: extra field present
    //                  bit 3 set: original file name present
    //                  bit 4 set: file comment present
    //                  bit 5 set: file is encrypted, encryption header present
    //                  bit 6,7:   reserved
    // 4      4 bytes  file modification time in Unix format
    // 8      1 byte   extra flags (depend on compression method)
    // 9      1 byte   OS type
    // [
    //        2 bytes  optional part number (second part=1)
    // ]?
    // [
    //        2 bytes  optional extra field length (e)
    //       (e)bytes  optional extra field
    // ]?
    // [
    //          bytes  optional original file name, zero terminated
    // ]?
    // [
    //          bytes  optional file comment, zero terminated
    // ]?
    // [
    //       12 bytes  optional encryption header
    // ]?
    //          bytes  compressed data
    //        4 bytes  crc32
    //        4 bytes  uncompressed input size modulo 2^32

    int signature = input.readUint16();
    if (signature != SIGNATURE) {
      throw new ArchiveException('Invalid GZip Signature');
    }

    int compressionMethod = input.readByte();
    if (compressionMethod != DEFLATE) {
      throw new ArchiveException('Invalid GZip Compression Methos');
    }

    int flags = input.readByte();
    /*int fileModTime =*/ input.readUint32();
    /*int extraFlags =*/ input.readByte();
    /*int osType =*/ input.readByte();

    if (flags & FLAG_EXTRA != 0) {
      int t = input.readUint16();
      input.readBytes(t);
    }

    if (flags & FLAG_NAME != 0) {
      input.readString();
    }

    if (flags & FLAG_COMMENT != 0) {
      input.readString();
    }

    // just throw away for now
    if (flags & FLAG_HCRC != 0) {
      input.readUint16();
    }
  }
}

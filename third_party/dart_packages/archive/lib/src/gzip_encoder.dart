part of archive;

class GZipEncoder {
  static const int SIGNATURE = 0x8b1f;
  static const int DEFLATE = 8;
  static const int FLAG_TEXT = 0x01;
  static const int FLAG_HCRC = 0x02;
  static const int FLAG_EXTRA = 0x04;
  static const int FLAG_NAME = 0x08;
  static const int FLAG_COMMENT = 0x10;

  // enum OperatingSystem
  static const int OS_FAT = 0;
  static const int OS_AMIGA = 1;
  static const int OS_VMS = 2;
  static const int OS_UNIX = 3;
  static const int OS_VM_CMS = 4;
  static const int OS_ATARI_TOS = 5;
  static const int OS_HPFS = 6;
  static const int OS_MACINTOSH = 7;
  static const int OS_Z_SYSTEM = 8;
  static const int OS_CP_M = 9;
  static const int OS_TOPS_20 = 10;
  static const int OS_NTFS = 11;
  static const int OS_QDOS = 12;
  static const int OS_ACORN_RISCOS = 13;
  static const int OS_UNKNOWN = 255;

  List<int> encode(data, {int level, dynamic output}) {
    dynamic output_stream = output != null ? output : new OutputStream();

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

    output_stream.writeUint16(SIGNATURE);
    output_stream.writeByte(DEFLATE);

    int flags = 0;
    int fileModTime = new DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int extraFlags = 0;
    int osType = OS_UNKNOWN;

    output_stream.writeByte(flags);
    output_stream.writeUint32(fileModTime);
    output_stream.writeByte(extraFlags);
    output_stream.writeByte(osType);

    Deflate deflate;
    if (data is List<int>) {
      deflate = new Deflate(data, level: level, output: output_stream);
    } else {
      deflate = new Deflate.buffer(data, level: level, output: output_stream);
    }

    if (!(output_stream is OutputStream)) {
      deflate.finish();
    }

    output_stream.writeUint32(deflate.crc32);

    output_stream.writeUint32(data.length);

    if (output_stream is OutputStream) {
      return output_stream.getBytes();
    } else {
      return null;
    }
  }
}

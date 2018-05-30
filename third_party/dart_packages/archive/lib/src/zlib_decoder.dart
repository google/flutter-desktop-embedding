part of archive;

/**
 * Decompress data with the zlib format decoder.
 */
class ZLibDecoder {
  static const int DEFLATE = 8;

  List<int> decodeBytes(List<int> data, {bool verify: false}) {
    return decodeBuffer(
        new InputStream(data, byteOrder: BIG_ENDIAN), verify: verify);
  }

  List<int> decodeBuffer(InputStream input, {bool verify: false}) {
    /*
     * The zlib format has the following structure:
     * CMF  1 byte
     * FLG 1 byte
     * [DICT_ID 4 bytes]? (if FLAG has FDICT (bit 5) set)
     * <compressed data>
     * ADLER32 4 bytes
     * ----
     * CMF:
     *    bits [0, 3] Compression Method, DEFLATE = 8
     *    bits [4, 7] Compression Info, base-2 logarithm of the LZ77 window
     *                size, minus eight (CINFO=7 indicates a 32K window size).
     * FLG:
     *    bits [0, 4] FCHECK (check bits for CMF and FLG)
     *    bits [5]    FDICT (preset dictionary)
     *    bits [6, 7] FLEVEL (compression level)
     */
    int cmf = input.readByte();
    int flg = input.readByte();

    int method = cmf & 8;
    int cinfo = (cmf >> 3) & 8; // ignore: unused_local_variable

    if (method != DEFLATE) {
      throw new ArchiveException('Only DEFLATE compression supported: ${method}');
    }

    int fcheck = flg & 16; // ignore: unused_local_variable
    int fdict = (flg & 32) >> 5;
    int flevel = (flg & 64) >> 6; // ignore: unused_local_variable

    // FCHECK is set such that (cmf * 256 + flag) must be a multiple of 31.
    if (((cmf << 8) + flg) % 31 != 0) {
      throw new ArchiveException('Invalid FCHECK');
    }

    int dictid; // ignore: unused_local_variable
    if (fdict != 0) {
      dictid = input.readUint32();
      throw new ArchiveException('FDICT Encoding not currently supported');
    }

    // Inflate
    List<int> buffer = new Inflate.buffer(input).getBytes();

    // verify adler-32
    int adler32 = input.readUint32();
    if (verify) {
      int a = getAdler32(buffer);
      if (adler32 != a) {
        throw new ArchiveException('Invalid adler-32 checksum');
      }
    }

    return buffer;
  }
}

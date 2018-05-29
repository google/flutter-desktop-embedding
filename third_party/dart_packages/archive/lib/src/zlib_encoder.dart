part of archive;

class ZLibEncoder {
  static const int DEFLATE = 8;

  List<int> encode(List<int> data, {int level}) {
    OutputStream output = new OutputStream(byteOrder: BIG_ENDIAN);

    // Compression Method and Flags
    int cm = DEFLATE;
    int cinfo = 7; //2^(7+8) = 32768 window size

    int cmf = (cinfo << 4) | cm;
    output.writeByte(cmf);

    // 0x01, (00 0 00001) (FLG)
    // bits 0 to 4  FCHECK  (check bits for CMF and FLG)
    // bit  5       FDICT   (preset dictionary)
    // bits 6 to 7  FLEVEL  (compression level)
    // FCHECK is set such that (cmf * 256 + flag) must be a multiple of 31.
    int fdict = 0;
    int flevel = 0;
    int flag = ((flevel & 0x3) << 7) | ((fdict & 0x1) << 5);
    int fcheck = 0;
    int cmf256 = cmf * 256;
    while ((cmf256 + (flag | fcheck)) % 31 != 0) {
      fcheck++;
    }
    flag |= fcheck;
    output.writeByte(flag);

    int adler32 = getAdler32(data);

    InputStream input = new InputStream(data, byteOrder: BIG_ENDIAN);

    List<int> compressed = new Deflate.buffer(input, level: level).getBytes();
    output.writeBytes(compressed);

    output.writeUint32(adler32);

    return output.getBytes();
  }
}

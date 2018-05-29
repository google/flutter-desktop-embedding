part of archive;

/**
 * A buffer that can be read as a stream of bytes.
 */
class InputStream {
  final List<int> buffer;
  int offset;
  final int start;
  final int byteOrder;

  /**
   * Create a InputStream for reading from a List<int>
   */
  InputStream(data, {this.byteOrder: LITTLE_ENDIAN, int start: 0,
              int length}) :
    this.buffer = data is ByteData ? new Uint8List.view(data.buffer) :
        data as List<int>,
    this.start = start {
    _length = length == null ? buffer.length : length;
    offset = start;
  }

  /**
   * Create a copy of [other].
   */
  InputStream.from(InputStream other) :
    buffer = other.buffer,
    offset = other.offset,
    start = other.start,
    _length = other._length,
    byteOrder = other.byteOrder;

  /**
   *  The current read position relative to the start of the buffer.
   */
  int get position => offset - start;

  /**
   * How many bytes are left in the stream.
   */
  int get length => _length - (offset - start);

  /**
   * Is the current position at the end of the stream?
   */
  bool get isEOS => offset >= (start + _length);

  /**
   * Reset to the beginning of the stream.
   */
  void reset() {
    offset = start;
  }

  /**
   * Rewind the read head of the stream by the given number of bytes.
   */
  void rewind([int length = 1]) {
    offset -= length;
    if (offset < 0) {
      offset = 0;
    }
  }

  /**
   * Access the buffer relative from the current position.
   */
  int operator[](int index) => buffer[offset + index];

  /**
   * Return a InputStream to read a subset of this stream.  It does not
   * move the read position of this stream.  [position] is specified relative
   * to the start of the buffer.  If [position] is not specified, the current
   * read position is used. If [length] is not specified, the remainder of this
   * stream is used.
   */
  InputStream subset([int position, int length]) {
    if (position == null) {
      position = this.offset;
    } else {
      position += start;
    }

    if (length == null || length < 0) {
      length = _length - (position - start);
    }

    return new InputStream(buffer, byteOrder: byteOrder, start: position,
                           length: length);
  }

  /**
   * Returns the position of the given [value] within the buffer, starting
   * from the current read position with the given [offset].  The position
   * returned is relative to the start of the buffer, or -1 if the [value]
   * was not found.
   */
  int indexOf(int value, [int offset = 0]) {
    for (int i = this.offset + offset, end = this.offset + length;
         i < end; ++i) {
      if (buffer[i] == value) {
        return i - this.start;
      }
    }
    return -1;
  }

  /**
   * Read [count] bytes from an [offset] of the current read position, without
   * moving the read position.
   */
  InputStream peekBytes(int count, [int offset = 0]) {
    return subset((this.offset - start) + offset, count);
  }

  /**
   * Move the read position by [count] bytes.
   */
  void skip(int count) {
    offset += count;
  }

  /**
   * Read a single byte.
   */
  int readByte() {
    return buffer[offset++];
  }

  /**
   * Read [count] bytes from the stream.
   */
  InputStream readBytes(int count) {
    InputStream bytes = subset(this.offset - start, count);
    offset += bytes.length;
    return bytes;
  }

  /**
   * Read a null-terminated string, or if [len] is provided, that number of
   * bytes returned as a string.
   */
  String readString([int len]) {
    if (len == null) {
      List<int> codes = [];
      while (!isEOS) {
        int c = readByte();
        if (c == 0) {
          return new String.fromCharCodes(codes);
        }
        codes.add(c);
      }
      throw new ArchiveException('EOF reached without finding string terminator');
    }

    InputStream s = readBytes(len);
    Uint8List bytes = s.toUint8List();
    String str = new String.fromCharCodes(bytes);
    return str;
  }

  /**
   * Read a 16-bit word from the stream.
   */
  int readUint16() {
    int b1 = buffer[offset++] & 0xff;
    int b2 = buffer[offset++] & 0xff;
    if (byteOrder == BIG_ENDIAN) {
      return (b1 << 8) | b2;
    }
    return (b2 << 8) | b1;
  }

  /**
   * Read a 24-bit word from the stream.
   */
  int readUint24() {
    int b1 = buffer[offset++] & 0xff;
    int b2 = buffer[offset++] & 0xff;
    int b3 = buffer[offset++] & 0xff;
    if (byteOrder == BIG_ENDIAN) {
      return b3 | (b2 << 8) | (b1 << 16);
    }
    return b1 | (b2 << 8) | (b3 << 16);
  }

  /**
   * Read a 32-bit word from the stream.
   */
  int readUint32() {
    int b1 = buffer[offset++] & 0xff;
    int b2 = buffer[offset++] & 0xff;
    int b3 = buffer[offset++] & 0xff;
    int b4 = buffer[offset++] & 0xff;
    if (byteOrder == BIG_ENDIAN) {
      return (b1 << 24) | (b2 << 16) | (b3 << 8) | b4;
    }
    return (b4 << 24) | (b3 << 16) | (b2 << 8) | b1;
  }

  /**
   * Read a 64-bit word form the stream.
   */
  int readUint64() {
    int b1 = buffer[offset++] & 0xff;
    int b2 = buffer[offset++] & 0xff;
    int b3 = buffer[offset++] & 0xff;
    int b4 = buffer[offset++] & 0xff;
    int b5 = buffer[offset++] & 0xff;
    int b6 = buffer[offset++] & 0xff;
    int b7 = buffer[offset++] & 0xff;
    int b8 = buffer[offset++] & 0xff;
    if (byteOrder == BIG_ENDIAN) {
      return (b1 << 56) | (b2 << 48) | (b3 << 40) | (b4 << 32) |
             (b5 << 24) | (b6 << 16) | (b7 << 8) | b8;
    }
    return (b8 << 56) | (b7 << 48) | (b6 << 40) | (b5 << 32) |
           (b4 << 24) | (b3 << 16) | (b2 << 8) | b1;
  }

  Uint8List toUint8List() {
    int len = length;
    if (buffer is Uint8List) {
      Uint8List b = buffer;
      if ((offset + len) > b.length) {
        len = b.length - offset;
      }
      Uint8List bytes = new Uint8List.view(b.buffer, offset, len);
      return bytes;
    }
    int end = offset + len;
    if (end > buffer.length) {
      end = buffer.length;
    }
    return new Uint8List.fromList(buffer.sublist(offset, end));
  }

  int _length;
}

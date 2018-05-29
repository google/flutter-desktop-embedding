part of archive;

/**
 * A helper class to work with List and TypedData in a way similar to pointers
 * in C.
 */
class MemPtr {
  var buffer;
  int offset;
  int _length;
  int byteOrder;

  MemPtr(List<int> other, [this.offset = 0, this._length = -1,
      this.byteOrder = LITTLE_ENDIAN]) {
    buffer = other;
    if (_length < 0 || _length > buffer.length) {
      _length = buffer.length;
    }
  }

  MemPtr.from(MemPtr other, [this.offset = 0, this._length = -1]) {
    buffer = other.buffer;
    offset += other.offset;
    byteOrder = other.byteOrder;
    if (_length < 0) {
      _length = other.length;
    }
    if (_length > buffer.length) {
      _length = buffer.length;
    }
  }

  /**
   * Are we at the end of the buffer?
   */
  bool get isEOS => offset >= _length;

  /**
   * Get a byte in the buffer relative to the current read position.
   */
  int operator[](int index) => buffer[offset + index];

  /**
   * Set a byte in the buffer relative to the current read position.
   */
  operator[]=(int index, int value) => buffer[offset + index] = value;

  /**
   * The number of bytes remaining in the buffer.
   */
  int get length => _length - offset;

  /**
   * Copy data from [other] to this buffer, at [start] offset from the
   * current read position, and [length] number of bytes.  [offset] is
   * the offset in [other] to start reading.
   */
  void memcpy(int start, int length, other, [int offset = 0]) {
    if (other is MemPtr) {
      buffer.setRange(this.offset + start, this.offset + start + length,
                      other.buffer, other.offset + offset);
    } else {
      buffer.setRange(this.offset + start, this.offset + start + length,
                      other, offset);
    }
  }

  /**
   * Set a range of bytes in this buffer to [value], at [start] offset from the
   * current read position, and [length] number of bytes.
   */
  void memset(int start, int length, int value) {
    buffer.fillRange(offset + start, offset + start + length, value);
  }

  /**
   * Read a single byte.
   */
  int readByte() {
    return buffer[offset++];
  }

  /**
   * Read [count] bytes from the buffer.
   */
  List<int> readBytes(int count) {
    if (buffer is Uint8List) {
      Uint8List bytes = new Uint8List.view(buffer.buffer,
                                           buffer.offsetInBytes + offset,
                                           count);
      offset += bytes.length;
      return bytes;
    }

    List<int> bytes = (buffer as List<int>).sublist(offset, offset + count);
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

    return new String.fromCharCodes(readBytes(len));
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
   * This assumes buffer is a Typed
   */
  Uint8List toUint8List([int offset = 0]) {
    return new Uint8List.view(buffer.buffer,
        buffer.offsetInBytes + this.offset + offset);
  }

  /**
   * This assumes buffer is a Typed
   */
  Uint32List toUint32List([int offset = 0]) {
    return new Uint32List.view(buffer.buffer,
        buffer.offsetInBytes + this.offset + offset);
  }
}

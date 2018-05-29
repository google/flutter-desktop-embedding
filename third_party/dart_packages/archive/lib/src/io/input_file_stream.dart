part of archive_io;

class InputFileStream {
  String path;
  io.RandomAccessFile _file;
  final int byteOrder;
  int _fileSize = 0;
  int _filePosition = 0;
  List<int> _buffer;
  int _bufferSize = 0;
  int _bufferPosition = 0;
  int _maxBufferSize;
  static const int _kDefaultBufferSize = 4096;

  InputFileStream(this.path, {this.byteOrder: LITTLE_ENDIAN,
    int bufferSize: _kDefaultBufferSize}) {
    _maxBufferSize = bufferSize;
    _buffer = new Uint8List(_maxBufferSize);
    _file = new io.File(path).openSync();
    _fileSize = _file.lengthSync();

    _readBuffer();
  }

  InputFileStream.file(io.File file, {this.byteOrder: LITTLE_ENDIAN,
    int bufferSize: _kDefaultBufferSize}) {
    _maxBufferSize = bufferSize;
    _buffer = new Uint8List(_maxBufferSize);
    _file = file.openSync();
    _fileSize = _file.lengthSync();
    _readBuffer();
  }

  void close() {
    _file.closeSync();
    _fileSize = 0;
  }

  int get length => _fileSize;

  int get position => _filePosition;

  bool get isEOS => (_filePosition >= _fileSize) &&
      (_bufferPosition >= _bufferSize);

  int get bufferSize => _bufferSize;

  int get bufferPosition => _bufferPosition;

  int get bufferRemaining => _bufferSize - _bufferPosition;

  int get fileRemaining => _fileSize - _filePosition;

  void reset() {
    _filePosition = 0;
    _file.setPositionSync(0);
    _readBuffer();
  }

  void skip(int length) {
    if ((_bufferPosition + length) < _bufferSize) {
      _bufferPosition += length;
    } else {
      int remaining = length - (_bufferSize - _bufferPosition);
      while (!isEOS) {
        _readBuffer();
        if (remaining < _bufferSize) {
          _bufferPosition += remaining;
          break;
        }
        remaining -= _bufferSize;
      }
    }
  }

  /**
   * Read [count] bytes from an [offset] of the current read position, without
   * moving the read position.
   */
  InputStream peekBytes(int count, [int offset = 0]) {
    int end = _bufferPosition + offset + count;
    if (end > 0 && end < _bufferSize) {
      List<int> bytes = _buffer.sublist(_bufferPosition + offset, end);
      return new InputStream(bytes);
    }

    Uint8List bytes = new Uint8List(count);

    int remaining = _bufferSize - (_bufferPosition + offset);
    if (remaining > 0) {
      List<int> bytes1 = _buffer.sublist(_bufferPosition + offset, _bufferSize);
      bytes.setRange(0, remaining, bytes1);
    }

    _file.readIntoSync(bytes, remaining, count);
    _file.setPositionSync(_filePosition);

    return new InputStream(bytes);
  }

  void rewind(int count) {
    if (_bufferPosition - count < 0) {
      int remaining = (_bufferPosition - count).abs();
      _filePosition = _filePosition - _bufferSize - remaining;
      if (_filePosition < 0) {
        _filePosition = 0;
      }
      _file.setPositionSync(_filePosition);
      _readBuffer();
      return;
    }
    _bufferPosition -= count;
  }

  int readByte() {
    if (isEOS) {
      return 0;
    }
    if (_bufferPosition >= _bufferSize) {
      _readBuffer();
    }
    if (_bufferPosition >= _bufferSize) {
      return 0;
    }
    return _buffer[_bufferPosition++] & 0xff;
  }

  /**
   * Read a 16-bit word from the stream.
   */
  int readUint16() {
    int b1 = 0;
    int b2 = 0;
    if ((_bufferPosition + 2) < _bufferSize) {
      b1 = _buffer[_bufferPosition++] & 0xff;
      b2 = _buffer[_bufferPosition++] & 0xff;
    } else {
      b1 = readByte();
      b2 = readByte();
    }
    if (byteOrder == BIG_ENDIAN) {
      return (b1 << 8) | b2;
    }
    return (b2 << 8) | b1;
  }

  /**
   * Read a 24-bit word from the stream.
   */
  int readUint24() {
    int b1 = 0;
    int b2 = 0;
    int b3 = 0;
    if ((_bufferPosition + 3) < _bufferSize) {
      b1 = _buffer[_bufferPosition++] & 0xff;
      b2 = _buffer[_bufferPosition++] & 0xff;
      b3 = _buffer[_bufferPosition++] & 0xff;
    } else {
      b1 = readByte();
      b2 = readByte();
      b3 = readByte();
    }

    if (byteOrder == BIG_ENDIAN) {
      return b3 | (b2 << 8) | (b1 << 16);
    }
    return b1 | (b2 << 8) | (b3 << 16);
  }

  /**
   * Read a 32-bit word from the stream.
   */
  int readUint32() {
    int b1 = 0;
    int b2 = 0;
    int b3 = 0;
    int b4 = 0;
    if ((_bufferPosition + 4) < _bufferSize) {
      b1 = _buffer[_bufferPosition++] & 0xff;
      b2 = _buffer[_bufferPosition++] & 0xff;
      b3 = _buffer[_bufferPosition++] & 0xff;
      b4 = _buffer[_bufferPosition++] & 0xff;
    } else {
      b1 = readByte();
      b2 = readByte();
      b3 = readByte();
      b4 = readByte();
    }

    if (byteOrder == BIG_ENDIAN) {
      return (b1 << 24) | (b2 << 16) | (b3 << 8) | b4;
    }
    return (b4 << 24) | (b3 << 16) | (b2 << 8) | b1;
  }

  /**
   * Read a 64-bit word form the stream.
   */
  int readUint64() {
    int b1 = 0;
    int b2 = 0;
    int b3 = 0;
    int b4 = 0;
    int b5 = 0;
    int b6 = 0;
    int b7 = 0;
    int b8 = 0;
    if ((_bufferPosition + 8) < _bufferSize) {
      b1 = _buffer[_bufferPosition++] & 0xff;
      b2 = _buffer[_bufferPosition++] & 0xff;
      b3 = _buffer[_bufferPosition++] & 0xff;
      b4 = _buffer[_bufferPosition++] & 0xff;
      b5 = _buffer[_bufferPosition++] & 0xff;
      b6 = _buffer[_bufferPosition++] & 0xff;
      b7 = _buffer[_bufferPosition++] & 0xff;
      b8 = _buffer[_bufferPosition++] & 0xff;
    } else {
      b1 = readByte();
      b2 = readByte();
      b3 = readByte();
      b4 = readByte();
      b5 = readByte();
      b6 = readByte();
      b7 = readByte();
      b8 = readByte();
    }

    if (byteOrder == BIG_ENDIAN) {
      return (b1 << 56) | (b2 << 48) | (b3 << 40) | (b4 << 32) |
      (b5 << 24) | (b6 << 16) | (b7 << 8) | b8;
    }
    return (b8 << 56) | (b7 << 48) | (b6 << 40) | (b5 << 32) |
    (b4 << 24) | (b3 << 16) | (b2 << 8) | b1;
  }

  InputStream readBytes(int length) {
    if (isEOS) {
      return null;
    }

    if (_bufferPosition == _bufferSize) {
      _readBuffer();
    }

    if (_remainingBufferSize >= length) {
      List<int> bytes = _buffer.sublist(_bufferPosition,
          _bufferPosition + length);
      _bufferPosition += length;
      return new InputStream(bytes);
    }

    int total_remaining = fileRemaining + _remainingBufferSize;
    if (length > total_remaining) {
      length = total_remaining;
    }

    Uint8List bytes = new Uint8List(length);

    int offset = 0;
    while (length > 0) {
      int remaining = _bufferSize - _bufferPosition;
      int end = (length > remaining) ? _bufferSize : (_bufferPosition + length);
      List<int> l = _buffer.sublist(_bufferPosition, end);
      // TODO probably better to use bytes.setRange here.
      for (int i = 0; i < l.length; ++i) {
        bytes[offset + i] = l[i];
      }
      offset += l.length;
      length -= l.length;
      _bufferPosition = end;
      if (length > 0 && _bufferPosition == _bufferSize) {
        _readBuffer();
        if (_bufferSize == 0) {
          break;
        }
      }
    }

    return new InputStream(bytes);
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

  int get _remainingBufferSize => _bufferSize - _bufferPosition;

  void _readBuffer() {
    _bufferPosition = 0;
    _bufferSize = _file.readIntoSync(_buffer);
    if (_bufferSize == 0) {
      return;
    }
    _filePosition += _bufferSize;
  }
}

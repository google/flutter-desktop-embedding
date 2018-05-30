part of archive;

/**
 * Get the Adler-32 checksum for the given array. You can append bytes to an
 * already computed adler checksum by specifying the previous [adler] value.
 */
int getAdler32(List<int> array, [int adler = 1]) {
  // largest prime smaller than 65536
  const int BASE = 65521;

  int s1 = adler & 0xffff;
  int s2 = adler >> 16;
  int len = array.length;
  int i = 0;
  while (len > 0) {
    int n = 3800;
    if (n > len) {
      n = len;
    }
    len -= n;
    while (--n >= 0) {
      s1 = s1 + (array[i++] & 0xff);
      s2 = s2 + s1;
    }
    s1 %= BASE;
    s2 %= BASE;
  }

  return (s2 << 16) | s1;
}

/**
 * A class to compute Adler-32 checksums.
 */
class Adler32 extends crypto.Hash {
  int _hash = 1;

  /**
   * Get the value of the hash directly. This returns the same value as [close].
   */
  int get hash => _hash;

  int get blockSize => 4;

  Adler32();

  Adler32 newInstance() => new Adler32();

  ByteConversionSink startChunkedConversion(Sink<crypto.Digest> sink) =>
      new _Adler32Sink(sink);

  void add(List<int> data) {
    _hash = getAdler32(data, _hash);
  }

  List<int> close() {
    return [((_hash >> 24) & 0xFF),
            ((_hash >> 16) & 0xFF),
            ((_hash >> 8) & 0xFF),
            (_hash & 0xFF)];
  }
}

/**
 * A [ByteConversionSink] that computes Adler-32 checksums.
 */
class _Adler32Sink extends ByteConversionSinkBase {
  final Sink<crypto.Digest> _inner;

  var _hash = 1;

  /// Whether [close] has been called.
  var _isClosed = false;

  _Adler32Sink(this._inner);

  void add(List<int> data) {
    if (_isClosed) throw new StateError('Hash.add() called after close().');
    _hash = getAdler32(data, _hash);
  }

  void close() {
    if (_isClosed) return;
    _isClosed = true;

    _inner.add(new crypto.Digest([
      ((_hash >> 24) & 0xFF),
      ((_hash >> 16) & 0xFF),
      ((_hash >> 8) & 0xFF),
      (_hash & 0xFF)
    ]));
  }
}

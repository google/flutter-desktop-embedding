// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library convert.hex.encoder;

import 'dart:convert';
import 'dart:typed_data';

import 'package:charcode/ascii.dart';

/// The canonical instance of [HexEncoder].
const hexEncoder = const HexEncoder._();

/// A converter that encodes byte arrays into hexadecimal strings.
///
/// This will throw a [RangeError] if the byte array has any digits that don't
/// fit in the gamut of a byte.
class HexEncoder extends Converter<List<int>, String> {
  const HexEncoder._();

  String convert(List<int> bytes) => _convert(bytes, 0, bytes.length);

  ByteConversionSink startChunkedConversion(Sink<String> sink) =>
      new _HexEncoderSink(sink);
}

/// A conversion sink for chunked hexadecimal encoding.
class _HexEncoderSink extends ByteConversionSinkBase {
  /// The underlying sink to which decoded byte arrays will be passed.
  final Sink<String> _sink;

  _HexEncoderSink(this._sink);

  void add(List<int> chunk) {
    _sink.add(_convert(chunk, 0, chunk.length));
  }

  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    RangeError.checkValidRange(start, end, chunk.length);
    _sink.add(_convert(chunk, start, end));
    if (isLast) _sink.close();
  }

  void close() {
    _sink.close();
  }
}

String _convert(List<int> bytes, int start, int end) {
  // A Uint8List is more efficient than a StringBuffer given that we know that
  // we're only emitting ASCII-compatible characters, and that we know the
  // length ahead of time.
  var buffer = new Uint8List((end - start) * 2);
  var bufferIndex = 0;

  // A bitwise OR of all bytes in [bytes]. This allows us to check for
  // out-of-range bytes without adding more branches than necessary to the
  // core loop.
  var byteOr = 0;
  for (var i = start; i < end; i++) {
    var byte = bytes[i];
    byteOr |= byte;

    // The bitwise arithmetic here is equivalent to `byte ~/ 16` and `byte % 16`
    // for valid byte values, but is easier for dart2js to optimize given that
    // it can't prove that [byte] will always be positive.
    buffer[bufferIndex++] = _codeUnitForDigit((byte & 0xF0) >> 4);
    buffer[bufferIndex++] = _codeUnitForDigit(byte & 0x0F);
  }

  if (byteOr >= 0 && byteOr <= 255) return new String.fromCharCodes(buffer);

  // If there was an invalid byte, find it and throw an exception.
  for (var i = start; i < end; i++) {
    var byte = bytes[i];
    if (byte >= 0 && byte <= 0xff) continue;
    throw new FormatException(
        "Invalid byte ${byte < 0 ? "-" : ""}0x${byte.abs().toRadixString(16)}.",
        bytes, i);
  }

  throw 'unreachable';
}

/// Returns the ASCII/Unicode code unit corresponding to the hexadecimal digit
/// [digit].
int _codeUnitForDigit(int digit) => digit < 10 ? digit + $0 : digit + $a - 10;

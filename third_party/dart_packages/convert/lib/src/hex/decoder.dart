// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library convert.hex.decoder;

import 'dart:convert';
import 'dart:typed_data';

import '../utils.dart';

/// The canonical instance of [HexDecoder].
const hexDecoder = const HexDecoder._();

/// A converter that decodes hexadecimal strings into byte arrays.
///
/// Because two hexadecimal digits correspond to a single byte, this will throw
/// a [FormatException] if given an odd-length string. It will also throw a
/// [FormatException] if given a string containing non-hexadecimal code units.
class HexDecoder extends Converter<String, List<int>> {
  const HexDecoder._();

  List<int> convert(String string) {
    if (!string.length.isEven) {
      throw new FormatException("Invalid input length, must be even.",
          string, string.length);
    }

    var bytes = new Uint8List(string.length ~/ 2);
    _decode(string.codeUnits, 0, string.length, bytes, 0);
    return bytes;
  }

  StringConversionSink startChunkedConversion(Sink<List<int>> sink) =>
      new _HexDecoderSink(sink);
}

/// A conversion sink for chunked hexadecimal decoding.
class _HexDecoderSink extends StringConversionSinkBase {
  /// The underlying sink to which decoded byte arrays will be passed.
  final Sink<List<int>> _sink;

  /// The trailing digit from the previous string.
  ///
  /// This will be non-`null` if the most recent string had an odd number of
  /// hexadecimal digits. Since it's the most significant digit, it's always a
  /// multiple of 16.
  int _lastDigit;

  _HexDecoderSink(this._sink);

  void addSlice(String string, int start, int end, bool isLast) {
    RangeError.checkValidRange(start, end, string.length);

    if (start == end) {
      if (isLast) _close(string, end);
      return;
    }

    var codeUnits = string.codeUnits;
    Uint8List bytes;
    int bytesStart;
    if (_lastDigit == null) {
      bytes = new Uint8List((end - start) ~/ 2);
      bytesStart = 0;
    } else {
      var hexPairs = (end - start - 1) ~/ 2;
      bytes = new Uint8List(1 + hexPairs);
      bytes[0] = _lastDigit + digitForCodeUnit(codeUnits, start);
      start++;
      bytesStart = 1;
    }

    _lastDigit = _decode(codeUnits, start, end, bytes, bytesStart);

    _sink.add(bytes);
    if (isLast) _close(string, end);
  }

  ByteConversionSink asUtf8Sink(bool allowMalformed) =>
      new _HexDecoderByteSink(_sink);

  void close() => _close();

  /// Like [close], but includes [string] and [index] in the [FormatException]
  /// if one is thrown.
  void _close([String string, int index]) {
    if (_lastDigit != null) {
      throw new FormatException(
          "Input ended with incomplete encoded byte.", string, index);
    }

    _sink.close();
  }
}

/// A conversion sink for chunked hexadecimal decoding from UTF-8 bytes.
class _HexDecoderByteSink extends ByteConversionSinkBase {
  /// The underlying sink to which decoded byte arrays will be passed.
  final Sink<List<int>> _sink;

  /// The trailing digit from the previous string.
  ///
  /// This will be non-`null` if the most recent string had an odd number of
  /// hexadecimal digits. Since it's the most significant digit, it's always a
  /// multiple of 16.
  int _lastDigit;

  _HexDecoderByteSink(this._sink);

  void add(List<int> chunk) => addSlice(chunk, 0, chunk.length, false);

  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    RangeError.checkValidRange(start, end, chunk.length);

    if (start == end) {
      if (isLast) _close(chunk, end);
      return;
    }

    Uint8List bytes;
    int bytesStart;
    if (_lastDigit == null) {
      bytes = new Uint8List((end - start) ~/ 2);
      bytesStart = 0;
    } else {
      var hexPairs = (end - start - 1) ~/ 2;
      bytes = new Uint8List(1 + hexPairs);
      bytes[0] = _lastDigit + digitForCodeUnit(chunk, start);
      start++;
      bytesStart = 1;
    }

    _lastDigit = _decode(chunk, start, end, bytes, bytesStart);

    _sink.add(bytes);
    if (isLast) _close(chunk, end);
  }

  void close() => _close();

  /// Like [close], but includes [chunk] and [index] in the [FormatException]
  /// if one is thrown.
  void _close([List<int> chunk, int index]) {
    if (_lastDigit != null) {
      throw new FormatException(
          "Input ended with incomplete encoded byte.", chunk, index);
    }

    _sink.close();
  }
}

/// Decodes [codeUnits] and writes the result into [destination].
///
/// This reads from [codeUnits] between [sourceStart] and [sourceEnd]. It writes
/// the result into [destination] starting at [destinationStart].
///
/// If there's a leftover digit at the end of the decoding, this returns that
/// digit. Otherwise it returns `null`.
int _decode(List<int> codeUnits, int sourceStart, int sourceEnd,
    List<int> destination, int destinationStart) {
  var destinationIndex = destinationStart;
  for (var i = sourceStart; i < sourceEnd - 1; i += 2) {
    var firstDigit = digitForCodeUnit(codeUnits, i);
    var secondDigit = digitForCodeUnit(codeUnits, i + 1);
    destination[destinationIndex++] = 16 * firstDigit + secondDigit;
  }

  if ((sourceEnd - sourceStart).isEven) return null;
  return 16 * digitForCodeUnit(codeUnits, sourceEnd - 1);
}

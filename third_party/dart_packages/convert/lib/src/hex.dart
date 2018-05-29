// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library convert.hex;

import 'dart:convert';

import 'hex/encoder.dart';
import 'hex/decoder.dart';

export 'hex/encoder.dart' hide hexEncoder;
export 'hex/decoder.dart' hide hexDecoder;

/// The canonical instance of [HexCodec].
const hex = const HexCodec._();

/// A codec that converts byte arrays to and from hexadecimal strings, following
/// [the Base16 spec][rfc].
///
/// [rfc]: https://tools.ietf.org/html/rfc4648#section-8
///
/// This should be used via the [hex] field.
class HexCodec extends Codec<List<int>, String> {
  HexEncoder get encoder => hexEncoder;
  HexDecoder get decoder => hexDecoder;

  const HexCodec._();
}

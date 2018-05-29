// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:convert/convert.dart';

/// A message digest as computed by a `Hash` or `HMAC` function.
class Digest {
  /// The message digest as an array of bytes.
  final List<int> bytes;

  Digest(this.bytes);

  /// Returns whether this is equal to another digest.
  ///
  /// This should be used instead of manual comparisons to avoid leaking
  /// information via timing.
  @override
  bool operator ==(Object other) =>
      other is Digest && const ListEquality().equals(bytes, other.bytes);

  @override
  int get hashCode => const ListEquality().hash(bytes);

  /// The message digest as a string of hexadecimal digits.
  @override
  String toString() => hex.encode(bytes);
}

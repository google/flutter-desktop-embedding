// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'digest.dart';

/// A sink used to get a digest value out of `Hash.startChunkedConversion`.
class DigestSink extends Sink<Digest> {
  /// The value added to the sink, if any.
  Digest get value {
    assert(_value != null);
    return _value;
  }

  Digest _value;

  /// Adds [value] to the sink.
  ///
  /// Unlike most sinks, this may only be called once.
  @override
  void add(Digest value) {
    assert(_value == null);
    _value = value;
  }

  @override
  void close() {
    assert(_value != null);
  }
}

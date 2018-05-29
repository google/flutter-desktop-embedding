// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";

/// Iterable that iterates over lists of values from other iterables.
///
/// When [iterator] is read, an [Iterator] is created for each [Iterable] in
/// the [Iterable] passed to the constructor.
///
/// As long as all these iterators have a next value, those next values are
/// combined into a single list, which becomes the next value of this
/// [Iterable]'s [Iterator]. As soon as any of the iterators run out,
/// the zipped iterator also stops.
class IterableZip<T> extends IterableBase<List<T>> {
  final Iterable<Iterable<T>> _iterables;

  IterableZip(Iterable<Iterable<T>> iterables) : this._iterables = iterables;

  /// Returns an iterator that combines values of the iterables' iterators
  /// as long as they all have values.
  Iterator<List<T>> get iterator {
    var iterators = _iterables.map((x) => x.iterator).toList(growable: false);
    // TODO(lrn): Return an empty iterator directly if iterators is empty?
    return new _IteratorZip<T>(iterators);
  }
}

class _IteratorZip<T> implements Iterator<List<T>> {
  final List<Iterator<T>> _iterators;
  List<T> _current;

  _IteratorZip(List<Iterator<T>> iterators) : _iterators = iterators;

  bool moveNext() {
    if (_iterators.isEmpty) return false;
    for (int i = 0; i < _iterators.length; i++) {
      if (!_iterators[i].moveNext()) {
        _current = null;
        return false;
      }
    }
    _current = new List(_iterators.length);
    for (int i = 0; i < _iterators.length; i++) {
      _current[i] = _iterators[i].current;
    }
    return true;
  }

  List<T> get current => _current;
}

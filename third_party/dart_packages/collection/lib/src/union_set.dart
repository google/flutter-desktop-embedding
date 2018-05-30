// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'unmodifiable_wrappers.dart';

/// A single set that provides a view of the union over a set of sets.
///
/// Since this is just a view, it reflects all changes in the underlying sets.
///
/// If an element is in multiple sets and the outer set is ordered, the version
/// in the earliest inner set is preferred. Component sets are assumed to use
/// `==` and `hashCode` for equality.
class UnionSet<E> extends SetBase<E> with UnmodifiableSetMixin<E> {
  /// The set of sets that this provides a view of.
  final Set<Set<E>> _sets;

  /// Whether the sets in [_sets] are guaranteed to be disjoint.
  final bool _disjoint;

  /// Creates a new set that's a view of the union of all sets in [sets].
  ///
  /// If any sets in [sets] change, this [UnionSet] reflects that change. If a
  /// new set is added to [sets], this [UnionSet] reflects that as well.
  ///
  /// If [disjoint] is `true`, then all component sets must be disjoint. That
  /// is, that they contain no elements in common. This makes many operations
  /// including [length] more efficient. If the component sets turn out not to
  /// be disjoint, some operations may behave inconsistently.
  UnionSet(this._sets, {bool disjoint: false}) : _disjoint = disjoint;

  /// Creates a new set that's a view of the union of all sets in [sets].
  ///
  /// If any sets in [sets] change, this [UnionSet] reflects that change.
  /// However, unlike [new UnionSet], this creates a copy of its parameter, so
  /// changes in [sets] aren't reflected in this [UnionSet].
  ///
  /// If [disjoint] is `true`, then all component sets must be disjoint. That
  /// is, that they contain no elements in common. This makes many operations
  /// including [length] more efficient. If the component sets turn out not to
  /// be disjoint, some operations may behave inconsistently.
  UnionSet.from(Iterable<Set<E>> sets, {bool disjoint: false})
      : this(sets.toSet(), disjoint: disjoint);

  int get length => _disjoint
      ? _sets.fold(0, (length, set) => length + set.length)
      : _iterable.length;

  Iterator<E> get iterator => _iterable.iterator;

  /// Returns an iterable over the contents of all the sets in [this].
  Iterable<E> get _iterable =>
      _disjoint ? _sets.expand((set) => set) : _dedupIterable;

  /// Returns an iterable over the contents of all the sets in [this] that
  /// de-duplicates elements.
  ///
  /// If the sets aren't guaranteed to be disjoint, this keeps track of the
  /// elements we've already emitted so that we can de-duplicate them.
  Iterable<E> get _dedupIterable {
    var seen = new Set<E>();
    return _sets.expand((set) => set).where((element) {
      if (seen.contains(element)) return false;
      seen.add(element);
      return true;
    });
  }

  bool contains(Object element) => _sets.any((set) => set.contains(element));

  E lookup(Object element) {
    if (element == null) return null;

    return _sets
        .map((set) => set.lookup(element))
        .firstWhere((result) => result != null, orElse: () => null);
  }

  Set<E> toSet() {
    var result = new Set<E>();
    for (var set in _sets) {
      result.addAll(set);
    }
    return result;
  }
}

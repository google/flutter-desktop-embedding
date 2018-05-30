// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'unmodifiable_wrappers.dart';

// Unfortunately, we can't use UnmodifiableSetMixin here, since const classes
// can't use mixins.
/// An unmodifiable, empty set that can have a const constructor.
class EmptyUnmodifiableSet<E> extends IterableBase<E>
    implements UnmodifiableSetView<E> {
  static T _throw<T>() {
    throw new UnsupportedError("Cannot modify an unmodifiable Set");
  }

  Iterator<E> get iterator => new Iterable<E>.empty().iterator;
  int get length => 0;

  const EmptyUnmodifiableSet();

  EmptyUnmodifiableSet<T> cast<T>() => new EmptyUnmodifiableSet<T>();
  bool contains(Object element) => false;
  bool containsAll(Iterable<Object> other) => other.isEmpty;
  Iterable<E> followedBy(Iterable<E> other) => new Set.from(other);
  E lookup(Object element) => null;
  EmptyUnmodifiableSet<T> retype<T>() => new EmptyUnmodifiableSet<T>();
  E singleWhere(bool test(E element), {E orElse()}) => super.singleWhere(test);
  Iterable<T> whereType<T>() => new EmptyUnmodifiableSet<T>();
  Set<E> toSet() => new Set();
  Set<E> union(Set<E> other) => new Set.from(other);
  Set<E> intersection(Set<Object> other) => new Set();
  Set<E> difference(Set<Object> other) => new Set();

  bool add(E value) => _throw();
  void addAll(Iterable<E> elements) => _throw();
  void clear() => _throw();
  bool remove(Object element) => _throw();
  void removeAll(Iterable<Object> elements) => _throw();
  void removeWhere(bool test(E element)) => _throw();
  void retainWhere(bool test(E element)) => _throw();
  void retainAll(Iterable<Object> elements) => _throw();
}

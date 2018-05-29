// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";
import "dart:math" as math;

import "wrappers.dart";

typedef F _UnaryFunction<E, F>(E argument);

/// The base class for delegating, type-asserting iterables.
///
/// Subclasses can provide a [_base] that should be delegated to. Unlike
/// [TypeSafeIterable], this allows the base to be created on demand.
abstract class _TypeSafeIterableBase<E> implements Iterable<E> {
  /// The base iterable to which operations are delegated.
  Iterable get _base;

  _TypeSafeIterableBase();

  bool any(bool test(E element)) => _base.any(_validate(test));

  // TODO: Dart 2.0 requires this method to be implemented.
  Iterable<T> cast<T>() {
    throw new UnimplementedError('cast');
  }

  bool contains(Object element) => _base.contains(element);

  E elementAt(int index) => _base.elementAt(index) as E;

  bool every(bool test(E element)) => _base.every(_validate(test));

  Iterable<T> expand<T>(Iterable<T> f(E element)) => _base.expand(_validate(f));

  E get first => _base.first as E;

  E firstWhere(bool test(E element), {E orElse()}) =>
      _base.firstWhere(_validate(test), orElse: orElse) as E;

  T fold<T>(T initialValue, T combine(T previousValue, E element)) =>
      _base.fold(initialValue,
          (previousValue, element) => combine(previousValue, element as E));

  // TODO: Dart 2.0 requires this method to be implemented.
  Iterable<E> followedBy(Iterable<E> other) {
    throw new UnimplementedError('followedBy');
  }

  void forEach(void f(E element)) => _base.forEach(_validate(f));

  bool get isEmpty => _base.isEmpty;

  bool get isNotEmpty => _base.isNotEmpty;

  Iterator<E> get iterator => _base.map((element) => element as E).iterator;

  String join([String separator = ""]) => _base.join(separator);

  E get last => _base.last as E;

  E lastWhere(bool test(E element), {E orElse()}) =>
      _base.lastWhere(_validate(test), orElse: orElse) as E;

  int get length => _base.length;

  Iterable<T> map<T>(T f(E element)) => _base.map(_validate(f));

  E reduce(E combine(E value, E element)) =>
      _base.reduce((value, element) => combine(value as E, element as E)) as E;

  // TODO: Dart 2.0 requires this method to be implemented.
  Iterable<T> retype<T>() {
    throw new UnimplementedError('retype');
  }

  E get single => _base.single as E;

  E singleWhere(bool test(E element), {E orElse()}) {
    if (orElse != null) throw new UnimplementedError('singleWhere:orElse');
    return _base.singleWhere(_validate(test)) as E;
  }

  Iterable<E> skip(int n) => new TypeSafeIterable<E>(_base.skip(n));

  Iterable<E> skipWhile(bool test(E value)) =>
      new TypeSafeIterable<E>(_base.skipWhile(_validate(test)));

  Iterable<E> take(int n) => new TypeSafeIterable<E>(_base.take(n));

  Iterable<E> takeWhile(bool test(E value)) =>
      new TypeSafeIterable<E>(_base.takeWhile(_validate(test)));

  List<E> toList({bool growable: true}) =>
      new TypeSafeList<E>(_base.toList(growable: growable));

  Set<E> toSet() => new TypeSafeSet<E>(_base.toSet());

  Iterable<E> where(bool test(E element)) =>
      new TypeSafeIterable<E>(_base.where(_validate(test)));

  // TODO: Dart 2.0 requires this method to be implemented.
  Iterable<T> whereType<T>() {
    throw new UnimplementedError('whereType');
  }

  String toString() => _base.toString();

  /// Returns a version of [function] that asserts that its argument is an
  /// instance of `E`.
  _UnaryFunction<dynamic, F> _validate<F>(F function(E value)) =>
      (value) => function(value as E);
}

/// An [Iterable] that asserts the types of values in a base iterable.
///
/// This is instantiated using [DelegatingIterable.typed].
class TypeSafeIterable<E> extends _TypeSafeIterableBase<E>
    implements DelegatingIterable<E> {
  final Iterable _base;

  TypeSafeIterable(Iterable base) : _base = base;
}

/// A [List] that asserts the types of values in a base list.
///
/// This is instantiated using [DelegatingList.typed].
class TypeSafeList<E> extends TypeSafeIterable<E> implements DelegatingList<E> {
  TypeSafeList(List base) : super(base);

  /// A [List]-typed getter for [_base].
  List get _listBase => _base;

  E operator [](int index) => _listBase[index] as E;

  void operator []=(int index, E value) {
    _listBase[index] = value;
  }

  // TODO: Dart 2.0 requires this method to be implemented.
  List<E> operator +(List<E> other) {
    throw new UnimplementedError('+');
  }

  void add(E value) {
    _listBase.add(value);
  }

  void addAll(Iterable<E> iterable) {
    _listBase.addAll(iterable);
  }

  Map<int, E> asMap() => new TypeSafeMap<int, E>(_listBase.asMap());

  // TODO: Dart 2.0 requires this method to be implemented.
  List<T> cast<T>() {
    throw new UnimplementedError('cast');
  }

  void clear() {
    _listBase.clear();
  }

  void fillRange(int start, int end, [E fillValue]) {
    _listBase.fillRange(start, end, fillValue);
  }

  // TODO: Dart 2.0 requires this method to be implemented.
  set first(E value) {
    if (this.isEmpty) throw new RangeError.index(0, this);
    this[0] = value;
  }

  Iterable<E> getRange(int start, int end) =>
      new TypeSafeIterable<E>(_listBase.getRange(start, end));

  int indexOf(E element, [int start = 0]) => _listBase.indexOf(element, start);

  // TODO: Dart 2.0 requires this method to be implemented.
  int indexWhere(bool test(E element), [int start = 0]) {
    throw new UnimplementedError('indexWhere');
  }

  void insert(int index, E element) {
    _listBase.insert(index, element);
  }

  void insertAll(int index, Iterable<E> iterable) {
    _listBase.insertAll(index, iterable);
  }

  // TODO: Dart 2.0 requires this method to be implemented.
  set last(E value) {
    if (this.isEmpty) throw new RangeError.index(0, this);
    this[this.length - 1] = value;
  }

  int lastIndexOf(E element, [int start]) =>
      _listBase.lastIndexOf(element, start);

  // TODO: Dart 2.0 requires this method to be implemented.
  int lastIndexWhere(bool test(E element), [int start]) {
    throw new UnimplementedError('lastIndexWhere');
  }

  set length(int newLength) {
    _listBase.length = newLength;
  }

  bool remove(Object value) => _listBase.remove(value);

  E removeAt(int index) => _listBase.removeAt(index) as E;

  E removeLast() => _listBase.removeLast() as E;

  void removeRange(int start, int end) {
    _listBase.removeRange(start, end);
  }

  void removeWhere(bool test(E element)) {
    _listBase.removeWhere(_validate(test));
  }

  void replaceRange(int start, int end, Iterable<E> iterable) {
    _listBase.replaceRange(start, end, iterable);
  }

  void retainWhere(bool test(E element)) {
    _listBase.retainWhere(_validate(test));
  }

  // TODO: Dart 2.0 requires this method to be implemented.
  List<T> retype<T>() {
    throw new UnimplementedError('retype');
  }

  Iterable<E> get reversed => new TypeSafeIterable<E>(_listBase.reversed);

  void setAll(int index, Iterable<E> iterable) {
    _listBase.setAll(index, iterable);
  }

  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    _listBase.setRange(start, end, iterable, skipCount);
  }

  void shuffle([math.Random random]) {
    _listBase.shuffle(random);
  }

  void sort([int compare(E a, E b)]) {
    if (compare == null) {
      _listBase.sort();
    } else {
      _listBase.sort((a, b) => compare(a as E, b as E));
    }
  }

  List<E> sublist(int start, [int end]) =>
      new TypeSafeList<E>(_listBase.sublist(start, end));
}

/// A [Set] that asserts the types of values in a base set.
///
/// This is instantiated using [DelegatingSet.typed].
class TypeSafeSet<E> extends TypeSafeIterable<E> implements DelegatingSet<E> {
  TypeSafeSet(Set base) : super(base);

  /// A [Set]-typed getter for [_base].
  Set get _setBase => _base;

  bool add(E value) => _setBase.add(value);

  void addAll(Iterable<E> elements) {
    _setBase.addAll(elements);
  }

  // TODO: Dart 2.0 requires this method to be implemented.
  Set<T> cast<T>() {
    throw new UnimplementedError('cast');
  }

  void clear() {
    _setBase.clear();
  }

  bool containsAll(Iterable<Object> other) => _setBase.containsAll(other);

  Set<E> difference(Set<Object> other) =>
      new TypeSafeSet<E>(_setBase.difference(other));

  Set<E> intersection(Set<Object> other) =>
      new TypeSafeSet<E>(_setBase.intersection(other));

  E lookup(Object element) => _setBase.lookup(element) as E;

  bool remove(Object value) => _setBase.remove(value);

  void removeAll(Iterable<Object> elements) {
    _setBase.removeAll(elements);
  }

  void removeWhere(bool test(E element)) {
    _setBase.removeWhere(_validate(test));
  }

  void retainAll(Iterable<Object> elements) {
    _setBase.retainAll(elements);
  }

  void retainWhere(bool test(E element)) {
    _setBase.retainWhere(_validate(test));
  }

  // TODO: Dart 2.0 requires this method to be implemented.
  Set<T> retype<T>() {
    throw new UnimplementedError('retype');
  }

  Set<E> union(Set<E> other) => new TypeSafeSet<E>(_setBase.union(other));
}

/// A [Queue] that asserts the types of values in a base queue.
///
/// This is instantiated using [DelegatingQueue.typed].
class TypeSafeQueue<E> extends TypeSafeIterable<E>
    implements DelegatingQueue<E> {
  TypeSafeQueue(Queue queue) : super(queue);

  /// A [Queue]-typed getter for [_base].
  Queue get _baseQueue => _base;

  void add(E value) {
    _baseQueue.add(value);
  }

  void addAll(Iterable<E> iterable) {
    _baseQueue.addAll(iterable);
  }

  void addFirst(E value) {
    _baseQueue.addFirst(value);
  }

  void addLast(E value) {
    _baseQueue.addLast(value);
  }

  // TODO: Dart 2.0 requires this method to be implemented.
  Queue<T> cast<T>() {
    throw new UnimplementedError('cast');
  }

  void clear() {
    _baseQueue.clear();
  }

  bool remove(Object object) => _baseQueue.remove(object);

  void removeWhere(bool test(E element)) {
    _baseQueue.removeWhere(_validate(test));
  }

  void retainWhere(bool test(E element)) {
    _baseQueue.retainWhere(_validate(test));
  }

  // TODO: Dart 2.0 requires this method to be implemented.
  Queue<T> retype<T>() {
    throw new UnimplementedError('retype');
  }

  E removeFirst() => _baseQueue.removeFirst() as E;

  E removeLast() => _baseQueue.removeLast() as E;
}

/// A [Map] that asserts the types of keys and values in a base map.
///
/// This is instantiated using [DelegatingMap.typed].
class TypeSafeMap<K, V> implements DelegatingMap<K, V> {
  /// The base map to which operations are delegated.
  final Map _base;

  TypeSafeMap(Map base) : _base = base;

  V operator [](Object key) => _base[key] as V;

  void operator []=(K key, V value) {
    _base[key] = value;
  }

  void addAll(Map<K, V> other) {
    _base.addAll(other);
  }

  // TODO: Dart 2.0 requires this method to be implemented.
  void addEntries(Iterable<Object> entries) {
    // Change Iterable<Object> to Iterable<MapEntry<K, V>> when
    // the MapEntry class has been added.
    throw new UnimplementedError('addEntries');
  }

  // TODO: Dart 2.0 requires this method to be implemented.
  Map<K2, V2> cast<K2, V2>() {
    throw new UnimplementedError('cast');
  }

  void clear() {
    _base.clear();
  }

  bool containsKey(Object key) => _base.containsKey(key);

  bool containsValue(Object value) => _base.containsValue(value);

  // TODO: Dart 2.0 requires this method to be implemented.
  Iterable<Null> get entries {
    // Change Iterable<Null> to Iterable<MapEntry<K, V>> when
    // the MapEntry class has been added.
    throw new UnimplementedError('entries');
  }

  void forEach(void f(K key, V value)) {
    _base.forEach((key, value) => f(key as K, value as V));
  }

  bool get isEmpty => _base.isEmpty;

  bool get isNotEmpty => _base.isNotEmpty;

  Iterable<K> get keys => new TypeSafeIterable<K>(_base.keys);

  int get length => _base.length;

  // TODO: Dart 2.0 requires this method to be implemented.
  Map<K2, V2> map<K2, V2>(Object transform(K key, V value)) {
    // Change Object to MapEntry<K2, V2> when
    // the MapEntry class has been added.
    throw new UnimplementedError('map');
  }

  V putIfAbsent(K key, V ifAbsent()) => _base.putIfAbsent(key, ifAbsent) as V;

  V remove(Object key) => _base.remove(key) as V;

  // TODO: Dart 2.0 requires this method to be implemented.
  void removeWhere(bool test(K key, V value)) {
    throw new UnimplementedError('removeWhere');
  }

  // TODO: Dart 2.0 requires this method to be implemented.
  Map<K2, V2> retype<K2, V2>() {
    throw new UnimplementedError('retype');
  }

  Iterable<V> get values => new TypeSafeIterable<V>(_base.values);

  String toString() => _base.toString();

  // TODO: Dart 2.0 requires this method to be implemented.
  V update(K key, V update(V value), {V ifAbsent()}) {
    throw new UnimplementedError('update');
  }

  // TODO: Dart 2.0 requires this method to be implemented.
  void updateAll(V update(K key, V value)) {
    throw new UnimplementedError('updateAll');
  }
}

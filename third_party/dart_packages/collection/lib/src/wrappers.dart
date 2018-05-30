// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";
import "dart:math" as math;

import "typed_wrappers.dart";
import "unmodifiable_wrappers.dart";

typedef K _KeyForValue<K, V>(V value);

/// A base class for delegating iterables.
///
/// Subclasses can provide a [_base] that should be delegated to. Unlike
/// [DelegatingIterable], this allows the base to be created on demand.
abstract class _DelegatingIterableBase<E> implements Iterable<E> {
  Iterable<E> get _base;

  const _DelegatingIterableBase();

  bool any(bool test(E element)) => _base.any(test);

  // TODO: Dart 2.0 requires this method to be implemented.
  Iterable<T> cast<T>() {
    throw new UnimplementedError('cast');
  }

  bool contains(Object element) => _base.contains(element);

  E elementAt(int index) => _base.elementAt(index);

  bool every(bool test(E element)) => _base.every(test);

  Iterable<T> expand<T>(Iterable<T> f(E element)) => _base.expand(f);

  E get first => _base.first;

  E firstWhere(bool test(E element), {E orElse()}) =>
      _base.firstWhere(test, orElse: orElse);

  T fold<T>(T initialValue, T combine(T previousValue, E element)) =>
      _base.fold(initialValue, combine);

  // TODO: Dart 2.0 requires this method to be implemented.
  Iterable<E> followedBy(Iterable<E> other) {
    throw new UnimplementedError('followedBy');
  }

  void forEach(void f(E element)) => _base.forEach(f);

  bool get isEmpty => _base.isEmpty;

  bool get isNotEmpty => _base.isNotEmpty;

  Iterator<E> get iterator => _base.iterator;

  String join([String separator = ""]) => _base.join(separator);

  E get last => _base.last;

  E lastWhere(bool test(E element), {E orElse()}) =>
      _base.lastWhere(test, orElse: orElse);

  int get length => _base.length;

  Iterable<T> map<T>(T f(E element)) => _base.map(f);

  E reduce(E combine(E value, E element)) => _base.reduce(combine);

  // TODO: Dart 2.0 requires this method to be implemented.
  Iterable<T> retype<T>() {
    throw new UnimplementedError('retype');
  }

  E get single => _base.single;

  E singleWhere(bool test(E element), {E orElse()}) {
    if (orElse != null) throw new UnimplementedError('singleWhere:orElse');
    return _base.singleWhere(test);
  }

  Iterable<E> skip(int n) => _base.skip(n);

  Iterable<E> skipWhile(bool test(E value)) => _base.skipWhile(test);

  Iterable<E> take(int n) => _base.take(n);

  Iterable<E> takeWhile(bool test(E value)) => _base.takeWhile(test);

  List<E> toList({bool growable: true}) => _base.toList(growable: growable);

  Set<E> toSet() => _base.toSet();

  Iterable<E> where(bool test(E element)) => _base.where(test);

  // TODO: Dart 2.0 requires this method to be implemented.
  Iterable<T> whereType<T>() {
    throw new UnimplementedError("whereType");
  }

  String toString() => _base.toString();
}

/// An [Iterable] that delegates all operations to a base iterable.
///
/// This class can be used to hide non-`Iterable` methods of an iterable object,
/// or it can be extended to add extra functionality on top of an existing
/// iterable object.
class DelegatingIterable<E> extends _DelegatingIterableBase<E> {
  final Iterable<E> _base;

  /// Creates a wrapper that forwards operations to [base].
  const DelegatingIterable(Iterable<E> base) : _base = base;

  /// Creates a wrapper that asserts the types of values in [base].
  ///
  /// This soundly converts an [Iterable] without a generic type to an
  /// `Iterable<E>` by asserting that its elements are instances of `E` whenever
  /// they're accessed. If they're not, it throws a [CastError].
  ///
  /// This forwards all operations to [base], so any changes in [base] will be
  /// reflected in [this]. If [base] is already an `Iterable<E>`, it's returned
  /// unmodified.
  static Iterable<E> typed<E>(Iterable base) =>
      base is Iterable<E> ? base : new TypeSafeIterable<E>(base);
}

/// A [List] that delegates all operations to a base list.
///
/// This class can be used to hide non-`List` methods of a list object, or it
/// can be extended to add extra functionality on top of an existing list
/// object.
class DelegatingList<E> extends DelegatingIterable<E> implements List<E> {
  const DelegatingList(List<E> base) : super(base);

  /// Creates a wrapper that asserts the types of values in [base].
  ///
  /// This soundly converts a [List] without a generic type to a `List<E>` by
  /// asserting that its elements are instances of `E` whenever they're
  /// accessed. If they're not, it throws a [CastError]. Note that even if an
  /// operation throws a [CastError], it may still mutate the underlying
  /// collection.
  ///
  /// This forwards all operations to [base], so any changes in [base] will be
  /// reflected in [this]. If [base] is already a `List<E>`, it's returned
  /// unmodified.
  static List<E> typed<E>(List base) =>
      base is List<E> ? base : new TypeSafeList<E>(base);

  List<E> get _listBase => _base;

  E operator [](int index) => _listBase[index];

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

  Map<int, E> asMap() => _listBase.asMap();

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

  Iterable<E> getRange(int start, int end) => _listBase.getRange(start, end);

  int indexOf(E element, [int start = 0]) => _listBase.indexOf(element, start);

  // TODO: Dart 2.0 requires this method to be implemented.
  int indexWhere(bool test(E element), [int start = 0]) {
    throw new UnimplementedError('indexWhere');
  }

  void insert(int index, E element) {
    _listBase.insert(index, element);
  }

  insertAll(int index, Iterable<E> iterable) {
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

  E removeAt(int index) => _listBase.removeAt(index);

  E removeLast() => _listBase.removeLast();

  void removeRange(int start, int end) {
    _listBase.removeRange(start, end);
  }

  void removeWhere(bool test(E element)) {
    _listBase.removeWhere(test);
  }

  void replaceRange(int start, int end, Iterable<E> iterable) {
    _listBase.replaceRange(start, end, iterable);
  }

  void retainWhere(bool test(E element)) {
    _listBase.retainWhere(test);
  }

  // TODO: Dart 2.0 requires this method to be implemented.
  List<T> retype<T>() {
    throw new UnimplementedError('retype');
  }

  Iterable<E> get reversed => _listBase.reversed;

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
    _listBase.sort(compare);
  }

  List<E> sublist(int start, [int end]) => _listBase.sublist(start, end);
}

/// A [Set] that delegates all operations to a base set.
///
/// This class can be used to hide non-`Set` methods of a set object, or it can
/// be extended to add extra functionality on top of an existing set object.
class DelegatingSet<E> extends DelegatingIterable<E> implements Set<E> {
  const DelegatingSet(Set<E> base) : super(base);

  /// Creates a wrapper that asserts the types of values in [base].
  ///
  /// This soundly converts a [Set] without a generic type to a `Set<E>` by
  /// asserting that its elements are instances of `E` whenever they're
  /// accessed. If they're not, it throws a [CastError]. Note that even if an
  /// operation throws a [CastError], it may still mutate the underlying
  /// collection.
  ///
  /// This forwards all operations to [base], so any changes in [base] will be
  /// reflected in [this]. If [base] is already a `Set<E>`, it's returned
  /// unmodified.
  static Set<E> typed<E>(Set base) =>
      base is Set<E> ? base : new TypeSafeSet<E>(base);

  Set<E> get _setBase => _base;

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

  Set<E> difference(Set<Object> other) => _setBase.difference(other);

  Set<E> intersection(Set<Object> other) => _setBase.intersection(other);

  E lookup(Object element) => _setBase.lookup(element);

  bool remove(Object value) => _setBase.remove(value);

  void removeAll(Iterable<Object> elements) {
    _setBase.removeAll(elements);
  }

  void removeWhere(bool test(E element)) {
    _setBase.removeWhere(test);
  }

  void retainAll(Iterable<Object> elements) {
    _setBase.retainAll(elements);
  }

  // TODO: Dart 2.0 requires this method to be implemented.
  Set<T> retype<T>() {
    throw new UnimplementedError('retype');
  }

  void retainWhere(bool test(E element)) {
    _setBase.retainWhere(test);
  }

  Set<E> union(Set<E> other) => _setBase.union(other);

  Set<E> toSet() => new DelegatingSet<E>(_setBase.toSet());
}

/// A [Queue] that delegates all operations to a base queue.
///
/// This class can be used to hide non-`Queue` methods of a queue object, or it
/// can be extended to add extra functionality on top of an existing queue
/// object.
class DelegatingQueue<E> extends DelegatingIterable<E> implements Queue<E> {
  const DelegatingQueue(Queue<E> queue) : super(queue);

  /// Creates a wrapper that asserts the types of values in [base].
  ///
  /// This soundly converts a [Queue] without a generic type to a `Queue<E>` by
  /// asserting that its elements are instances of `E` whenever they're
  /// accessed. If they're not, it throws a [CastError]. Note that even if an
  /// operation throws a [CastError], it may still mutate the underlying
  /// collection.
  ///
  /// This forwards all operations to [base], so any changes in [base] will be
  /// reflected in [this]. If [base] is already a `Queue<E>`, it's returned
  /// unmodified.
  static Queue<E> typed<E>(Queue base) =>
      base is Queue<E> ? base : new TypeSafeQueue<E>(base);

  Queue<E> get _baseQueue => _base;

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
    _baseQueue.removeWhere(test);
  }

  void retainWhere(bool test(E element)) {
    _baseQueue.retainWhere(test);
  }

  // TODO: Dart 2.0 requires this method to be implemented.
  Queue<T> retype<T>() {
    throw new UnimplementedError('retype');
  }

  E removeFirst() => _baseQueue.removeFirst();

  E removeLast() => _baseQueue.removeLast();
}

/// A [Map] that delegates all operations to a base map.
///
/// This class can be used to hide non-`Map` methods of an object that extends
/// `Map`, or it can be extended to add extra functionality on top of an
/// existing map object.
class DelegatingMap<K, V> implements Map<K, V> {
  final Map<K, V> _base;

  const DelegatingMap(Map<K, V> base) : _base = base;

  /// Creates a wrapper that asserts the types of keys and values in [base].
  ///
  /// This soundly converts a [Map] without generic types to a `Map<K, V>` by
  /// asserting that its keys are instances of `E` and its values are instances
  /// of `V` whenever they're accessed. If they're not, it throws a [CastError].
  /// Note that even if an operation throws a [CastError], it may still mutate
  /// the underlying collection.
  ///
  /// This forwards all operations to [base], so any changes in [base] will be
  /// reflected in [this]. If [base] is already a `Map<K, V>`, it's returned
  /// unmodified.
  static Map<K, V> typed<K, V>(Map base) =>
      base is Map<K, V> ? base : new TypeSafeMap<K, V>(base);

  V operator [](Object key) => _base[key];

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

  void clear() {
    _base.clear();
  }

  // TODO: Dart 2.0 requires this method to be implemented.
  Map<K2, V2> cast<K2, V2>() {
    throw new UnimplementedError('cast');
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
    _base.forEach(f);
  }

  bool get isEmpty => _base.isEmpty;

  bool get isNotEmpty => _base.isNotEmpty;

  Iterable<K> get keys => _base.keys;

  int get length => _base.length;

  // TODO: Dart 2.0 requires this method to be implemented.
  Map<K2, V2> map<K2, V2>(Object transform(K key, V value)) {
    // Change Object to MapEntry<K2, V2> when
    // the MapEntry class has been added.
    throw new UnimplementedError('map');
  }

  V putIfAbsent(K key, V ifAbsent()) => _base.putIfAbsent(key, ifAbsent);

  V remove(Object key) => _base.remove(key);

  // TODO: Dart 2.0 requires this method to be implemented.
  void removeWhere(bool test(K key, V value)) {
    throw new UnimplementedError('removeWhere');
  }

  // TODO: Dart 2.0 requires this method to be implemented.
  Map<K2, V2> retype<K2, V2>() {
    throw new UnimplementedError('retype');
  }

  Iterable<V> get values => _base.values;

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

/// An unmodifiable [Set] view of the keys of a [Map].
///
/// The set delegates all operations to the underlying map.
///
/// A `Map` can only contain each key once, so its keys can always
/// be viewed as a `Set` without any loss, even if the [Map.keys]
/// getter only shows an [Iterable] view of the keys.
///
/// Note that [lookup] is not supported for this set.
class MapKeySet<E> extends _DelegatingIterableBase<E>
    with UnmodifiableSetMixin<E> {
  final Map<E, dynamic> _baseMap;

  MapKeySet(Map<E, dynamic> base) : _baseMap = base;

  Iterable<E> get _base => _baseMap.keys;

  // TODO: Dart 2.0 requires this method to be implemented.
  Set<T> cast<T>() {
    throw new UnimplementedError('cast');
  }

  bool contains(Object element) => _baseMap.containsKey(element);

  bool get isEmpty => _baseMap.isEmpty;

  bool get isNotEmpty => _baseMap.isNotEmpty;

  int get length => _baseMap.length;

  String toString() => "{${_base.join(', ')}}";

  bool containsAll(Iterable<Object> other) => other.every(contains);

  /// Returns a new set with the the elements of [this] that are not in [other].
  ///
  /// That is, the returned set contains all the elements of this [Set] that are
  /// not elements of [other] according to `other.contains`.
  ///
  /// Note that the returned set will use the default equality operation, which
  /// may be different than the equality operation [this] uses.
  Set<E> difference(Set<Object> other) =>
      where((element) => !other.contains(element)).toSet();

  /// Returns a new set which is the intersection between [this] and [other].
  ///
  /// That is, the returned set contains all the elements of this [Set] that are
  /// also elements of [other] according to `other.contains`.
  ///
  /// Note that the returned set will use the default equality operation, which
  /// may be different than the equality operation [this] uses.
  Set<E> intersection(Set<Object> other) => where(other.contains).toSet();

  /// Throws an [UnsupportedError] since there's no corresponding method for
  /// [Map]s.
  E lookup(Object element) =>
      throw new UnsupportedError("MapKeySet doesn't support lookup().");

  // TODO: Dart 2.0 requires this method to be implemented.
  Set<T> retype<T>() {
    throw new UnimplementedError('retype');
  }

  /// Returns a new set which contains all the elements of [this] and [other].
  ///
  /// That is, the returned set contains all the elements of this [Set] and all
  /// the elements of [other].
  ///
  /// Note that the returned set will use the default equality operation, which
  /// may be different than the equality operation [this] uses.
  Set<E> union(Set<E> other) => toSet()..addAll(other);
}

/// Creates a modifiable [Set] view of the values of a [Map].
///
/// The `Set` view assumes that the keys of the `Map` can be uniquely determined
/// from the values. The `keyForValue` function passed to the constructor finds
/// the key for a single value. The `keyForValue` function should be consistent
/// with equality. If `value1 == value2` then `keyForValue(value1)` and
/// `keyForValue(value2)` should be considered equal keys by the underlying map,
/// and vice versa.
///
/// Modifying the set will modify the underlying map based on the key returned
/// by `keyForValue`.
///
/// If the `Map` contents are not compatible with the `keyForValue` function,
/// the set will not work consistently, and may give meaningless responses or do
/// inconsistent updates.
///
/// This set can, for example, be used on a map from database record IDs to the
/// records. It exposes the records as a set, and allows for writing both
/// `recordSet.add(databaseRecord)` and `recordMap[id]`.
///
/// Effectively, the map will act as a kind of index for the set.
class MapValueSet<K, V> extends _DelegatingIterableBase<V> implements Set<V> {
  final Map<K, V> _baseMap;
  final _KeyForValue<K, V> _keyForValue;

  /// Creates a new [MapValueSet] based on [base].
  ///
  /// [keyForValue] returns the key in the map that should be associated with
  /// the given value. The set's notion of equality is identical to the equality
  /// of the return values of [keyForValue].
  MapValueSet(Map<K, V> base, K keyForValue(V value))
      : _baseMap = base,
        _keyForValue = keyForValue;

  Iterable<V> get _base => _baseMap.values;

  // TODO: Dart 2.0 requires this method to be implemented.
  Set<T> cast<T>() {
    throw new UnimplementedError('cast');
  }

  bool contains(Object element) {
    if (element != null && element is! V) return false;
    var key = _keyForValue(element as V);

    return _baseMap.containsKey(key);
  }

  bool get isEmpty => _baseMap.isEmpty;

  bool get isNotEmpty => _baseMap.isNotEmpty;

  int get length => _baseMap.length;

  String toString() => toSet().toString();

  bool add(V value) {
    K key = _keyForValue(value);
    bool result = false;
    _baseMap.putIfAbsent(key, () {
      result = true;
      return value;
    });
    return result;
  }

  void addAll(Iterable<V> elements) => elements.forEach(add);

  void clear() => _baseMap.clear();

  bool containsAll(Iterable<Object> other) => other.every(contains);

  /// Returns a new set with the the elements of [this] that are not in [other].
  ///
  /// That is, the returned set contains all the elements of this [Set] that are
  /// not elements of [other] according to `other.contains`.
  ///
  /// Note that the returned set will use the default equality operation, which
  /// may be different than the equality operation [this] uses.
  Set<V> difference(Set<Object> other) =>
      where((element) => !other.contains(element)).toSet();

  /// Returns a new set which is the intersection between [this] and [other].
  ///
  /// That is, the returned set contains all the elements of this [Set] that are
  /// also elements of [other] according to `other.contains`.
  ///
  /// Note that the returned set will use the default equality operation, which
  /// may be different than the equality operation [this] uses.
  Set<V> intersection(Set<Object> other) => where(other.contains).toSet();

  V lookup(Object element) {
    if (element != null && element is! V) return null;
    var key = _keyForValue(element as V);

    return _baseMap[key];
  }

  bool remove(Object element) {
    if (element != null && element is! V) return false;
    var key = _keyForValue(element as V);

    if (!_baseMap.containsKey(key)) return false;
    _baseMap.remove(key);
    return true;
  }

  void removeAll(Iterable<Object> elements) => elements.forEach(remove);

  void removeWhere(bool test(V element)) {
    var toRemove = [];
    _baseMap.forEach((key, value) {
      if (test(value)) toRemove.add(key);
    });
    toRemove.forEach(_baseMap.remove);
  }

  void retainAll(Iterable<Object> elements) {
    var valuesToRetain = new Set<V>.identity();
    for (var element in elements) {
      if (element != null && element is! V) continue;
      var key = _keyForValue(element as V);

      if (!_baseMap.containsKey(key)) continue;
      valuesToRetain.add(_baseMap[key]);
    }

    var keysToRemove = [];
    _baseMap.forEach((k, v) {
      if (!valuesToRetain.contains(v)) keysToRemove.add(k);
    });
    keysToRemove.forEach(_baseMap.remove);
  }

  void retainWhere(bool test(V element)) =>
      removeWhere((element) => !test(element));

  // TODO: Dart 2.0 requires this method to be implemented.
  Set<T> retype<T>() {
    throw new UnimplementedError('retype');
  }

  /// Returns a new set which contains all the elements of [this] and [other].
  ///
  /// That is, the returned set contains all the elements of this [Set] and all
  /// the elements of [other].
  ///
  /// Note that the returned set will use the default equality operation, which
  /// may be different than the equality operation [this] uses.
  Set<V> union(Set<V> other) => toSet()..addAll(other);
}

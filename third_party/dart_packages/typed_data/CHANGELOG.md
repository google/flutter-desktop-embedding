## 1.1.5

* Undo unnessesary SDK version constraint tweak.

## 1.1.4

* Expand the SDK version constraint to include `<2.0.0-dev.infinity`.

## 1.1.3

* Fix all strong-mode warnings.

## 1.1.2

* Fix a bug where `TypedDataBuffer.insertAll` could fail to insert some elements
  of an `Iterable`.

## 1.1.1

* Optimize `insertAll` with an `Iterable` argument and no end-point.

## 1.1.0

* Add `start` and `end` parameters to the `addAll()` and `insertAll()` methods
  for the typed data buffer classes. These allow efficient concatenation of
  slices of existing typed data.

* Make `addAll()` for typed data buffer classes more efficient for lists,
  especially typed data lists.

## 1.0.0

* ChangeLog starts here

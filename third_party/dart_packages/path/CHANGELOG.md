## 1.5.1

* Fix a number of bugs that occurred when the current working directory was `/`
  on Linux or Mac OS.

## 1.5.0

* Add a `setExtension()` top-level function and `Context` method.

## 1.4.2

* Treat `package:` URLs as absolute.

* Normalize `c:\foo\.` to `c:\foo`.

## 1.4.1

* Root-relative URLs like `/foo` are now resolved relative to the drive letter
  for `file` URLs that begin with a Windows-style drive letter. This matches the
  [WHATWG URL specification][].

[WHATWG URL specification]: https://url.spec.whatwg.org/#file-slash-state

* When a root-relative URLs like `/foo` is converted to a Windows path using
  `fromUrl()`, it is now resolved relative to the drive letter. This matches
  IE's behavior.

## 1.4.0

* Add `equals()`, `hash()` and `canonicalize()` top-level functions and
  `Context` methods. These make it easier to treat paths as map keys.

* Properly compare Windows paths case-insensitively.

* Further improve the performance of `isWithin()`.

## 1.3.9

* Further improve the performance of `isWithin()` when paths contain `/.`
  sequences that aren't `/../`.

## 1.3.8

* Improve the performance of `isWithin()` when the paths don't contain
  asymmetrical `.` or `..` components.

* Improve the performance of `relative()` when `from` is `null` and the path is
  already relative.

* Improve the performance of `current` when the current directory hasn't
  changed.

## 1.3.7

* Improve the performance of `absolute()` and `normalize()`.

## 1.3.6

* Ensure that `path.toUri` preserves trailing slashes for relative paths.

## 1.3.5

* Added type annotations to top-level and static fields.

## 1.3.4

* Fix dev_compiler warnings.

## 1.3.3

* Performance improvement in `Context.relative` - don't call `current` if `from`
  is not relative.

## 1.3.2

* Fix some analyzer hints.

## 1.3.1

* Add a number of performance improvements.

## 1.3.0

* Expose a top-level `context` field that provides access to a `Context` object
  for the current system.

## 1.2.3

* Don't cache path Context based on cwd, as cwd involves a system-call to
  compute.

## 1.2.2

* Remove the documentation link from the pubspec so this is linked to
  pub.dartlang.org by default.

# 1.2.1

* Many members on `Style` that provided access to patterns and functions used
  internally for parsing paths have been deprecated.

* Manually parse paths (rather than using RegExps to do so) for better
  performance.

# 1.2.0

* Added `path.prettyUri`, which produces a human-readable representation of a
  URI.

# 1.1.0

* `path.fromUri` now accepts strings as well as `Uri` objects.

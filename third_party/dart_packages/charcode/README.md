Character code constants.

[![Build Status](https://travis-ci.org/dart-lang/charcode.svg?branch=master)](https://travis-ci.org/dart-lang/charcode)
[![Pub](https://img.shields.io/pub/v/charcode.svg)](https://pub.dartlang.org/packages/charcode)

These libraries define symbolic names for some character codes.

## Using

Import either one of the libraries:

```dart
import "package:charcode/ascii.dart";
import "package:charcode/html_entity.dart";
```

or import both libraries using the `charcode.dart` library:

```dart
import "package:charcode/charcode.dart";
```

# Naming

The character names are preceded by a `$` to avoid conflicting with other
variables due to the short and common names (for example "$i").

The characters that are valid in a Dart identifier directly follow the `$`.
Examples: `$_`, `$a`, `$B` and `$3`. Other characters are given symbolic names.

The names of letters are lower-case for lower-case letters, and mixed- or
upper-case for upper-case letters. The names of symbols are all lower-case,
and omit suffixes like "sign", "symbol" and "mark".
Examples: `$plus`, `$exclamation`

The `ascii.dart` library defines a symbolic name for each ASCII character.
For some characters, it has more than one name. For example the common `$tab`
and the official `$ht` for the horizontal tab.

The `html_entity.dart` library defines a constant for each HTML 4.01 character
entity, using the standard entity abbreviation, including its case.
Examples: `$nbsp` for `&nbps;`, `$aring` for the lower-case `&aring;`
and `$Aring` for the upper-case `&Aring;`.

The HTML entities includes all characters in the Latin-1 code page, greek
letters and some mathematical symbols.

The `charcode.dart` library just exports both `ascii.dart` and
`html_entity.dart`.

# Rationale

The Dart language doesn't have character literals. If that ever happens, this
library will be irrelevant. Until then, this library can be used for the most
common characters.
See [request for character literals](http://dartbug.com/4415).

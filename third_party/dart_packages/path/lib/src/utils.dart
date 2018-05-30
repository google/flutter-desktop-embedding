// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'characters.dart' as chars;

/// Returns whether [char] is the code for an ASCII letter (uppercase or
/// lowercase).
bool isAlphabetic(int char) =>
    (char >= chars.UPPER_A && char <= chars.UPPER_Z) ||
    (char >= chars.LOWER_A && char <= chars.LOWER_Z);

/// Returns whether [char] is the code for an ASCII digit.
bool isNumeric(int char) => char >= chars.ZERO && char <= chars.NINE;

/// Returns whether [path] has a URL-formatted Windows drive letter beginning at
/// [index].
bool isDriveLetter(String path, int index) {
  if (path.length < index + 2) return false;
  if (!isAlphabetic(path.codeUnitAt(index))) return false;
  if (path.codeUnitAt(index + 1) != chars.COLON) return false;
  if (path.length == index + 2) return true;
  return path.codeUnitAt(index + 2) == chars.SLASH;
}

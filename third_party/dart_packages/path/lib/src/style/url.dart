// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../characters.dart' as chars;
import '../internal_style.dart';
import '../utils.dart';

/// The style for URL paths.
class UrlStyle extends InternalStyle {
  UrlStyle();

  final name = 'url';
  final separator = '/';
  final separators = const ['/'];

  // Deprecated properties.

  final separatorPattern = new RegExp(r'/');
  final needsSeparatorPattern =
      new RegExp(r"(^[a-zA-Z][-+.a-zA-Z\d]*://|[^/])$");
  final rootPattern = new RegExp(r"[a-zA-Z][-+.a-zA-Z\d]*://[^/]*");
  final relativeRootPattern = new RegExp(r"^/");

  bool containsSeparator(String path) => path.contains('/');

  bool isSeparator(int codeUnit) => codeUnit == chars.SLASH;

  bool needsSeparator(String path) {
    if (path.isEmpty) return false;

    // A URL that doesn't end in "/" always needs a separator.
    if (!isSeparator(path.codeUnitAt(path.length - 1))) return true;

    // A URI that's just "scheme://" needs an extra separator, despite ending
    // with "/".
    return path.endsWith("://") && rootLength(path) == path.length;
  }

  int rootLength(String path, {bool withDrive: false}) {
    if (path.isEmpty) return 0;
    if (isSeparator(path.codeUnitAt(0))) return 1;

    for (var i = 0; i < path.length; i++) {
      var codeUnit = path.codeUnitAt(i);
      if (isSeparator(codeUnit)) return 0;
      if (codeUnit == chars.COLON) {
        if (i == 0) return 0;

        // The root part is up until the next '/', or the full path. Skip ':'
        // (and '//' if it exists) and search for '/' after that.
        if (path.startsWith('//', i + 1)) i += 3;
        var index = path.indexOf('/', i);
        if (index <= 0) return path.length;

        // file: URLs sometimes consider Windows drive letters part of the root.
        // See https://url.spec.whatwg.org/#file-slash-state.
        if (!withDrive || path.length < index + 3) return index;
        if (!path.startsWith('file://')) return index;
        if (!isDriveLetter(path, index + 1)) return index;
        return path.length == index + 3 ? index + 3 : index + 4;
      }
    }

    return 0;
  }

  bool isRootRelative(String path) =>
      path.isNotEmpty && isSeparator(path.codeUnitAt(0));

  String getRelativeRoot(String path) => isRootRelative(path) ? '/' : null;

  String pathFromUri(Uri uri) => uri.toString();

  Uri relativePathToUri(String path) => Uri.parse(path);
  Uri absolutePathToUri(String path) => Uri.parse(path);
}

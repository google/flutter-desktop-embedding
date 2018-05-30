# archive
[![Build Status](https://travis-ci.org/brendan-duncan/archive.svg?branch=master)](https://travis-ci.org/brendan-duncan/archive)

## Overview

A Dart library to encode and decode various archive and compression formats.

The library has no reliance on `dart:io`, so it can be used for both server and
web applications.

The archive library currently supports the following decoders:

- Zip (Archive)
- Tar (Archive)
- ZLib [Inflate decompression]
- GZip [Inflate decompression]
- BZip2 [decompression]

And the following encoders:

- Zip (Archive)
- Tar (Archive)
- ZLib [Deflate compression]
- GZip [Deflate compression]
- BZip2 [compression]

## Sample

Extract the contents of a Zip file, and encode the contents as a BZip2
compressed Tar file:

```dart
import 'dart:io';
import 'package:archive/archive.dart';
void main() {
  // Read the Zip file from disk.
  List<int> bytes = new File('test.zip').readAsBytesSync();

  // Decode the Zip file
  Archive archive = new ZipDecoder().decodeBytes(bytes);

  // Extract the contents of the Zip archive to disk.
  for (ArchiveFile file in archive) {
    String filename = file.name;
    List<int> data = file.content;
    new File('out/' + filename)
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
  }

  // Encode the archive as a BZip2 compressed Tar file.
  List<int> tar_data = new TarEncoder().encode(archive);
  List<int> tar_bz2 = new BZip2Encoder().encode(tar_data);

  // Write the compressed tar file to disk.
  File fp = new File(filename + '.tbz');
  fp.writeAsBytesSync(tar_bz2);
}
```

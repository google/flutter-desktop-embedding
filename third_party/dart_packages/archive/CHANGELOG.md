## 1.0.33

* Support the latest version of `package:args`.

## 1.0.30 - May 27, 2017

- Add archive_io sub-package for supporting file streaming rather than storing everything in memory.
  **This is a work-in-progress and under development.**

## 1.0.29 - May 25, 2017

- Fix issue with POSIX tar files.
- Upgrade dependency on `archive` to `>=1.0.0 <2.0.0`

## 1.0.20 - Jun2 21, 2015

- Improve performance decompressing large files in zip archives.

## 1.0.19 - February 23, 2014

- Disable CRC verification by default when decoding archives.

## 1.0.18 - October 09, 2014

- Add support for encoding uncompressed files in zip archives.

## 1.0.17 - April 25, 2014

- Fix a bug in InputStream.

## 1.0.16 - March 02, 2014

- Add stream support to Inflate decompression.

## 1.0.15 - February 16, 2014

- Improved performance when writing large blocks.

## 1.0.14 - February 12, 2014

- Misc updates and fixes.

## 1.0.13 - February 06, 2014

- Added BZip2 encoder.

- *BREAKING CHANGE*: `File` was renamed to `ArchiveFile`, to avoid conflicts with
  `dart:io`.

## 1.0.12 - February 04, 2014

- Added BZip2 decoder.

## 1.0.11 - February 02, 2014

- Changed `InputStream` to work with typed_data instead of `List<int>`, should
  reduce memory and increase performance.

## 1.0.10 - January 19, 2013

- Renamed `InputBuffer` and `OutputBuffer` to `InputStream` and `OutputStream`,
  respectively.

- Added `readBits` method to `InputStream`.

part of archive;

/**
 * An exception thrown when there was a problem in the archive library.
 */
class ArchiveException implements Exception {
  /// A message describing the error.
  final String message;

  ArchiveException(this.message);

  String toString() => "ArchiveException: $message";
}

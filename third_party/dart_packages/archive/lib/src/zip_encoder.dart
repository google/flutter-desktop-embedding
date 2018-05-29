part of archive;

/**
 * Encode an [Archive] object into a Zip formatted buffer.
 */
class ZipEncoder {
  List<int> encode(Archive archive, {int level: Deflate.BEST_SPEED}) {
    DateTime dateTime = new DateTime.now();
    int t1 = ((dateTime.minute & 0x7) << 5) | (dateTime.second ~/ 2);
    int t2 = (dateTime.hour << 3) | (dateTime.minute >> 3);
    int time = ((t2 & 0xff) << 8) | (t1 & 0xff);

    int d1 = ((dateTime.month & 0x7) << 5) | dateTime.day;
    int d2 = (((dateTime.year - 1980) & 0x7f) << 1)
             | (dateTime.month >> 3);
    int date = ((d2 & 0xff) << 8) | (d1 & 0xff);

    int localFileSize = 0;
    int centralDirectorySize = 0;
    int endOfCentralDirectorySize = 0;

    Map<ArchiveFile, Map> fileData = {};

    // Prepare the files, so we can know ahead of time how much space we need
    // for the output buffer.
    for (ArchiveFile file in archive.files) {
      fileData[file] = {};
      fileData[file]['time'] = time;
      fileData[file]['date'] = date;

      InputStream compressedData;
      int crc32;

      // If the user want's to store the file without compressing it,
      // make sure it's decompressed.
      if (!file.compress) {
        if (file.isCompressed) {
          file.decompress();
        }

        compressedData = new InputStream(file.content);

        if (file.crc32 != null) {
          crc32 = file.crc32;
        } else {
          crc32 = getCrc32(file.content);
        }
      } else if (!file.compress ||
                 file.compressionType == ArchiveFile.DEFLATE) {
        // If the file is already compressed, no sense in uncompressing it and
        // compressing it again, just pass along the already compressed data.
        compressedData = file.rawContent;

        if (file.crc32 != null) {
          crc32 = file.crc32;
        } else {
          crc32 = getCrc32(file.content);
        }
      } else {
        // Otherwise we need to compress it now.
        crc32 = getCrc32(file.content);

        List<int> bytes = new Deflate(file.content, level: level).getBytes();
        compressedData = new InputStream(bytes);
      }

      localFileSize += 30 + file.name.length + compressedData.length;

      centralDirectorySize += 46 + file.name.length +
                             (file.comment != null ? file.comment.length : 0);

      fileData[file]['crc'] = crc32;
      fileData[file]['size'] = compressedData.length;
      fileData[file]['data'] = compressedData;
    }

    endOfCentralDirectorySize = 46 +
        (archive.comment != null ? archive.comment.length : 0);

    int outputSize = localFileSize + centralDirectorySize +
                     endOfCentralDirectorySize;

    OutputStream output = new OutputStream(size: outputSize);

    // Write Local File Headers
    for (ArchiveFile file in archive.files) {
      fileData[file]['pos'] = output.length;
      _writeFile(file, fileData, output);
    }

    // Write Central Directory and End Of Central Directory
    _writeCentralDirectory(archive, fileData, output);

    return output.getBytes();
  }

  void _writeFile(ArchiveFile file, Map fileData, OutputStream output) {
    output.writeUint32(ZipFile.SIGNATURE);

    int version = VERSION;
    int flags = 0;
    int compressionMethod = file.compress ? ZipFile.DEFLATE : ZipFile.STORE;
    int lastModFileTime = fileData[file]['time'];
    int lastModFileDate = fileData[file]['date'];
    int crc32 = fileData[file]['crc'];
    int compressedSize = fileData[file]['size'];
    int uncompressedSize = file.size;
    String filename = file.name;
    List<int> extra = [];

    InputStream compressedData = fileData[file]['data'];

    output.writeUint16(version);
    output.writeUint16(flags);
    output.writeUint16(compressionMethod);
    output.writeUint16(lastModFileTime);
    output.writeUint16(lastModFileDate);
    output.writeUint32(crc32);
    output.writeUint32(compressedSize);
    output.writeUint32(uncompressedSize);
    output.writeUint16(filename.length);
    output.writeUint16(extra.length);
    output.writeBytes(filename.codeUnits);
    output.writeBytes(extra);

    output.writeInputStream(compressedData);
  }

  void _writeCentralDirectory(Archive archive, Map fileData,
                              OutputStream output) {
    int centralDirPosition = output.length;

    int version = VERSION;
    int os = OS_MSDOS;

    for (ArchiveFile file in archive.files) {
      int versionMadeBy = (os << 8) | version;
      int versionNeededToExtract = version;
      int generalPurposeBitFlag = 0;
      int compressionMethod = file.compress ? ZipFile.DEFLATE : ZipFile.STORE;
      int lastModifiedFileTime = fileData[file]['time'];
      int lastModifiedFileDate = fileData[file]['date'];
      int crc32 = fileData[file]['crc'];
      int compressedSize = fileData[file]['size'];
      int uncompressedSize = file.size;
      int diskNumberStart = 0;
      int internalFileAttributes = 0;
      int externalFileAttributes = 0;
      int localHeaderOffset = fileData[file]['pos'];
      String filename = file.name;
      List<int> extraField = [];
      String fileComment = (file.comment == null ? '' : file.comment);

      output.writeUint32(ZipFileHeader.SIGNATURE);
      output.writeUint16(versionMadeBy);
      output.writeUint16(versionNeededToExtract);
      output.writeUint16(generalPurposeBitFlag);
      output.writeUint16(compressionMethod);
      output.writeUint16(lastModifiedFileTime);
      output.writeUint16(lastModifiedFileDate);
      output.writeUint32(crc32);
      output.writeUint32(compressedSize);
      output.writeUint32(uncompressedSize);
      output.writeUint16(filename.length);
      output.writeUint16(extraField.length);
      output.writeUint16(fileComment.length);
      output.writeUint16(diskNumberStart);
      output.writeUint16(internalFileAttributes);
      output.writeUint32(externalFileAttributes);
      output.writeUint32(localHeaderOffset);
      output.writeBytes(filename.codeUnits);
      output.writeBytes(extraField);
      output.writeBytes(fileComment.codeUnits);
    }

    int numberOfThisDisk = 0;
    int diskWithTheStartOfTheCentralDirectory = 0;
    int totalCentralDirectoryEntriesOnThisDisk = archive.numberOfFiles();
    int totalCentralDirectoryEntries = archive.numberOfFiles();
    int centralDirectorySize = output.length - centralDirPosition;
    int centralDirectoryOffset = centralDirPosition;
    String comment = (archive.comment == null ? '' : archive.comment);

    output.writeUint32(ZipDirectory.SIGNATURE);
    output.writeUint16(numberOfThisDisk);
    output.writeUint16(diskWithTheStartOfTheCentralDirectory);
    output.writeUint16(totalCentralDirectoryEntriesOnThisDisk);
    output.writeUint16(totalCentralDirectoryEntries);
    output.writeUint32(centralDirectorySize);
    output.writeUint32(centralDirectoryOffset);
    output.writeUint16(comment.length);
    output.writeBytes(comment.codeUnits);
  }

  static const int VERSION = 20;

  // enum OS
  static const int OS_MSDOS = 0;
  static const int OS_UNIX = 3;
  static const int OS_MACINTOSH = 7;
}

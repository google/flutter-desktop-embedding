part of archive;

/**
 * Decode a tar formatted buffer into an [Archive] object.
 */
class TarDecoder {
  List<TarFile> files = [];

  Archive decodeBytes(List<int> data, {bool verify: false,
      bool storeData: true}) {
    return decodeBuffer(new InputStream(data), verify: verify,
        storeData: storeData);
  }

  Archive decodeBuffer(dynamic input, {bool verify: false,
      bool storeData: true}) {
    Archive archive = new Archive();
    files.clear();

    //TarFile paxHeader = null;
    while (!input.isEOS) {
      // End of archive when two consecutive 0's are found.
      InputStream end_check = input.peekBytes(2);
      if (end_check.length < 2 || (end_check[0] == 0 && end_check[1] == 0)) {
        break;
      }

      TarFile tf = new TarFile.read(input, storeData: storeData);
      // In POSIX formatted tar files, a separate 'PAX' file contains extended
      // metadata for files. These are identified by having a type flag 'X'.
      // TODO parse these metadata values.
      if (tf.typeFlag == TarFile.TYPE_G_EX_HEADER ||
          tf.typeFlag == TarFile.TYPE_G_EX_HEADER2) {
        // TODO handle PAX global header.
      }
      if (tf.typeFlag == TarFile.TYPE_EX_HEADER ||
          tf.typeFlag == TarFile.TYPE_EX_HEADER2) {
        //paxHeader = tf;
      } else {
        files.add(tf);

        ArchiveFile file = new ArchiveFile(
            tf.filename, tf.fileSize, tf._rawContent);

        file.mode = tf.mode;
        file.ownerId = tf.ownerId;
        file.groupId = tf.groupId;
        file.lastModTime = tf.lastModTime;
        file.isFile = tf.isFile;

        archive.addFile(file);
      }
    }

    return archive;
  }
}

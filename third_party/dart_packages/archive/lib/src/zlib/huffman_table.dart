part of archive;

/**
 * Build huffman table from length list.
 */
class HuffmanTable {
  Uint32List table;
  int maxCodeLength = 0;
  int minCodeLength = 0x7fffffff;

  HuffmanTable(List<int> lengths) {
    int listSize = lengths.length;

    for (int i = 0; i < listSize; ++i) {
      if (lengths[i] > maxCodeLength) {
        maxCodeLength = lengths[i];
      }
      if (lengths[i] < minCodeLength) {
        minCodeLength = lengths[i];
      }
    }

    int size = 1 << maxCodeLength;
    table = new Uint32List(size);

    for (int bitLength = 1, code = 0, skip = 2; bitLength <= maxCodeLength;) {
      for (int i = 0; i < listSize; ++i) {
        if (lengths[i] == bitLength) {
          int reversed = 0;
          int rtemp = code;
          for (int j = 0; j < bitLength; ++j) {
            reversed = (reversed << 1) | (rtemp & 1);
            rtemp >>= 1;
          }

          for (int j = reversed; j < size; j += skip) {
            table[j] = (bitLength << 16) | i;
          }

          ++code;
        }
      }

      ++bitLength;
      code <<= 1;
      skip <<= 1;
    }
  }
}

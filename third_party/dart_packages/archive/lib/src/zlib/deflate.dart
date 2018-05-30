part of archive;


class Deflate {
  // enum CompressionLevel
  static const int DEFAULT_COMPRESSION = 6;
  static const int BEST_COMPRESSION = 9;
  static const int BEST_SPEED = 1;
  static const int NO_COMPRESSION = 0;

  // enum FlushMode
  static const int NO_FLUSH = 0;
  static const int PARTIAL_FLUSH = 1;
  static const int SYNC_FLUSH = 2;
  static const int FULL_FLUSH = 3;
  static const int FINISH = 4;

  int crc32;

  Deflate(List<int> bytes, {int level: DEFAULT_COMPRESSION,
           int flush: FINISH, dynamic output})
    : _input = new InputStream(bytes),
      _output = output != null ? output : new OutputStream() {
    crc32 = 0;
    _init(level);
    _deflate(flush);
  }

  Deflate.buffer(this._input, {int level: DEFAULT_COMPRESSION,
                  int flush: FINISH, dynamic output})
    : _output = output != null ? output : new OutputStream() {
    crc32 = 0;
    _init(level);
    _deflate(flush);
  }

  void finish() {
    _flushPending();
  }

  /**
   * Get the resulting compressed bytes.
   */
  List<int> getBytes() {
    _flushPending();
    return _output.getBytes();
  }

  /**
   * Get the resulting compressed bytes without storing the resulting data to
   * minimize memory usage.
   */
  List<int> takeBytes() {
    _flushPending();
    List<int> bytes = _output.getBytes();
    _output.clear();
    return bytes;
  }

  /**
   * Add more data to be deflated.
   */
  void addBytes(List<int> bytes, {int flush: FINISH}) {
    _input = new InputStream(bytes);
    _deflate(flush);
  }

  /**
   * Add more data to be deflated.
   */
  void addBuffer(InputStream buffer, {int flush: FINISH}) {
    _input = buffer;
    _deflate(flush);
  }

  /**
   * Compression level used (1..9)
   */
  int get level => _level;

  /**
   * Initialize the deflate structures for the given parameters.
   */
  void _init(int level,
             {int method: Z_DEFLATED,
             int windowBits: MAX_WBITS,
             int memLevel: DEF_MEM_LEVEL,
             int strategy: Z_DEFAULT_STRATEGY}) {
    if (level == null || level == Z_DEFAULT_COMPRESSION) {
      level = 6;
    }

    _config = _getConfig(level);

    if (memLevel < 1 || memLevel > MAX_MEM_LEVEL || method != Z_DEFLATED ||
        windowBits < 9 || windowBits > 15 || level < 0 || level > 9 ||
        strategy < 0 || strategy > Z_HUFFMAN_ONLY) {
      throw new ArchiveException('Invalid Deflate parameter');
    }

    _dynamicLengthTree = new Uint16List(HEAP_SIZE * 2);
    _dynamicDistTree = new Uint16List((2 * D_CODES + 1) * 2);
    _bitLengthTree = new Uint16List((2 * BL_CODES + 1) * 2);

    _windowBits = windowBits;
    _windowSize = 1 << _windowBits;
    _windowMask = _windowSize - 1;

    _hashBits = memLevel + 7;
    _hashSize = 1 << _hashBits;
    _hashMask = _hashSize - 1;
    _hashShift = ((_hashBits + MIN_MATCH - 1) ~/ MIN_MATCH);

    _window = new Uint8List(_windowSize * 2);
    _prev = new Uint16List(_windowSize);
    _head = new Uint16List(_hashSize);

    _litBufferSize = 1 << (memLevel + 6); // 16K elements by default

    // We overlay pending_buf and d_buf+l_buf. This works since the average
    // output size for (length,distance) codes is <= 24 bits.
    _pendingBuffer = new Uint8List(_litBufferSize * 4);
    _pendingBufferSize = _litBufferSize * 4;

    _dbuf = _litBufferSize;
    _lbuf = (1 + 2) * _litBufferSize;

    _level = level;

    _strategy = strategy;
    _method = method;

    _pending = 0;
    _pendingOut = 0;

    _status = BUSY_STATE;

    _lastFlush = NO_FLUSH;

    crc32 = 0;

    _trInit();
    _lmInit();
  }

  /**
   * Compress the current input buffer.
   */
  int _deflate(int flush) {
    if (flush > FINISH || flush < 0) {
      throw new ArchiveException('Invalid Deflate Parameter');
    }

    _lastFlush = flush;

    // Flush as much pending output as possible
    if (_pending != 0) {
      // Make sure there is something to do and avoid duplicate consecutive
      // flushes. For repeated and useless calls with FINISH, we keep
      // returning Z_STREAM_END instead of Z_BUFF_ERROR.
      _flushPending();
    }

    // Start a new block or continue the current one.
    if (!_input.isEOS || _lookAhead != 0 ||
        (flush != NO_FLUSH && _status != FINISH_STATE)) {
      int bstate = -1;
      switch (_config.function) {
        case STORED:
          bstate = _deflateStored(flush);
          break;
        case FAST:
          bstate = _deflateFast(flush);
          break;
        case SLOW:
          bstate = _deflateSlow(flush);
          break;
        default:
          break;
      }

      if (bstate == FINISH_STARTED || bstate == FINISH_DONE) {
        _status = FINISH_STATE;
      }

      if (bstate == NEED_MORE || bstate == FINISH_STARTED) {
        // If flush != Z_NO_FLUSH && avail_out == 0, the next call
        // of deflate should use the same flush parameter to make sure
        // that the flush is complete. So we don't have to output an
        // empty block here, this will be done at next call. This also
        // ensures that for a very small output buffer, we emit at most
        // one empty block.
        return Z_OK;
      }

      if (bstate == BLOCK_DONE) {
        if (flush == PARTIAL_FLUSH) {
          _trAlign();
        } else {
          // FULL_FLUSH or SYNC_FLUSH
          _trStoredBlock(0, 0, false);
          // For a full flush, this empty block will be recognized
          // as a special marker by inflate_sync().
          if (flush == FULL_FLUSH) {
            for (int i = 0; i < _hashSize; i++) {
              // forget history
              _head[i] = 0;
            }
          }
        }

        _flushPending();
      }
    }

    if (flush != FINISH) {
      return Z_OK;
    }

    return Z_STREAM_END;
  }

  void _lmInit() {
    _actualWindowSize = 2 * _windowSize;

    _head[_hashSize - 1] = 0;
    for (int i = 0; i < _hashSize - 1; i++) {
      _head[i] = 0;
    }

    _strStart = 0;
    _blockStart = 0;
    _lookAhead = 0;
    _matchLength = _prevLength = MIN_MATCH - 1;
    _matchAvailable = 0;
    _insertHash = 0;
  }

  /**
   * Initialize the tree data structures for a new zlib stream.
   */
  void _trInit() {
    _lDesc.dynamicTree = _dynamicLengthTree;
    _lDesc.staticDesc = _StaticTree.staticLDesc;

    _dDesc.dynamicTree = _dynamicDistTree;
    _dDesc.staticDesc = _StaticTree.staticDDesc;

    _blDesc.dynamicTree = _bitLengthTree;
    _blDesc.staticDesc = _StaticTree.staticBlDesc;

    _bitBuffer = 0;
    _numValidBits = 0;
    _lastEOBLen = 8; // enough lookahead for inflate

    // Initialize the first block of the first file:
    _initBlock();
  }

  void _initBlock() {
    // Initialize the trees.
    for (int i = 0; i < L_CODES; i++) {
      _dynamicLengthTree[i * 2] = 0;
    }
    for (int i = 0; i < D_CODES; i++) {
      _dynamicDistTree[i * 2] = 0;
    }
    for (int i = 0; i < BL_CODES; i++) {
      _bitLengthTree[i * 2] = 0;
    }

    _dynamicLengthTree[END_BLOCK * 2] = 1;
    _optimalLen = _staticLen = 0;
    _lastLit = _matches = 0;
  }

  /**
   * Restore the heap property by moving down the tree starting at node k,
   * exchanging a node with the smallest of its two sons if necessary, stopping
   * when the heap property is re-established (each father smaller than its
   * two sons).
   */
  void _pqdownheap(Uint16List tree, int k) {
    int v = _heap[k];
    int j = k << 1; // left son of k
    while (j <= _heapLen) {
      // Set j to the smallest of the two sons:
      if (j < _heapLen && _smaller(tree, _heap[j + 1], _heap[j], _depth)) {
        j++;
      }
      // Exit if v is smaller than both sons
      if (_smaller(tree, v, _heap[j], _depth)) {
        break;
      }

      // Exchange v with the smallest son
      _heap[k] = _heap[j]; k = j;
      // And continue down the tree, setting j to the left son of k
      j <<= 1;
    }
    _heap[k] = v;
  }

  static bool _smaller(Uint16List tree, int n, int m,
                       Uint8List depth) {
    return (tree[n * 2] < tree[m * 2] ||
            (tree[n * 2] == tree[m * 2] && depth[n] <= depth[m]));
  }

  /**
   * Scan a literal or distance tree to determine the frequencies of the codes
   * in the bit length tree.
   */
  void _scanTree(Uint16List tree, int max_code) {
    int n; // iterates over all tree elements
    int prevlen = - 1; // last emitted length
    int curlen; // length of current code
    int nextlen = tree[0 * 2 + 1]; // length of next code
    int count = 0; // repeat count of the current code
    int max_count = 7; // max repeat count
    int min_count = 4; // min repeat count

    if (nextlen == 0) {
      max_count = 138; min_count = 3;
    }
    tree[(max_code + 1) * 2 + 1] = 0xffff; // guard

    for (n = 0; n <= max_code; n++) {
      curlen = nextlen; nextlen = tree[(n + 1) * 2 + 1];
      if (++count < max_count && curlen == nextlen) {
        continue;
      } else if (count < min_count) {
        _bitLengthTree[curlen * 2] = (_bitLengthTree[curlen * 2] + count);
      } else if (curlen != 0) {
        if (curlen != prevlen) {
          _bitLengthTree[curlen * 2]++;
        }
        _bitLengthTree[REP_3_6 * 2]++;
      } else if (count <= 10) {
        _bitLengthTree[REPZ_3_10 * 2]++;
      } else {
        _bitLengthTree[REPZ_11_138 * 2]++;
      }
      count = 0; prevlen = curlen;
      if (nextlen == 0) {
        max_count = 138; min_count = 3;
      } else if (curlen == nextlen) {
        max_count = 6; min_count = 3;
      } else {
        max_count = 7; min_count = 4;
      }
    }
  }

  // Construct the Huffman tree for the bit lengths and return the index in
  // bl_order of the last bit length code to send.
  int _buildBitLengthTree() {
    int max_blindex; // index of last bit length code of non zero freq

    // Determine the bit length frequencies for literal and distance trees
    _scanTree(_dynamicLengthTree, _lDesc.maxCode);
    _scanTree(_dynamicDistTree, _dDesc.maxCode);

    // Build the bit length tree:
    _blDesc._buildTree(this);
    // opt_len now includes the length of the tree representations, except
    // the lengths of the bit lengths codes and the 5+5+4 bits for the counts.

    // Determine the number of bit length codes to send. The pkzip format
    // requires that at least 4 bit length codes be sent. (appnote.txt says
    // 3 but the actual value used is 4.)
    for (max_blindex = BL_CODES - 1; max_blindex >= 3; max_blindex--) {
      if (_bitLengthTree[_HuffmanTree.BL_ORDER[max_blindex] * 2 + 1] != 0) {
        break;
      }
    }

    // Update opt_len to include the bit length tree and counts
    _optimalLen += 3 * (max_blindex + 1) + 5 + 5 + 4;

    return max_blindex;
  }


  /**
   * Send the header for a block using dynamic Huffman trees: the counts, the
   * lengths of the bit length codes, the literal tree and the distance tree.
   * IN assertion: lcodes >= 257, dcodes >= 1, blcodes >= 4.
   */
  void _sendAllTrees(int lcodes, int dcodes, int blcodes) {
    int rank; // index in bl_order

    _sendBits(lcodes - 257, 5); // not +255 as stated in appnote.txt
    _sendBits(dcodes - 1, 5);
    _sendBits(blcodes - 4, 4); // not -3 as stated in appnote.txt
    for (rank = 0; rank < blcodes; rank++) {
      _sendBits(_bitLengthTree[_HuffmanTree.BL_ORDER[rank] * 2 + 1], 3);
    }
    _sendTree(_dynamicLengthTree, lcodes - 1); // literal tree
    _sendTree(_dynamicDistTree, dcodes - 1); // distance tree
  }

  /**
   * Send a literal or distance tree in compressed form, using the codes in
   * bl_tree.
   */
  void _sendTree(Uint16List tree, int max_code) {
    int n; // iterates over all tree elements
    int prevlen = - 1; // last emitted length
    int curlen; // length of current code
    int nextlen = tree[0 * 2 + 1]; // length of next code
    int count = 0; // repeat count of the current code
    int max_count = 7; // max repeat count
    int min_count = 4; // min repeat count

    if (nextlen == 0) {
      max_count = 138; min_count = 3;
    }

    for (n = 0; n <= max_code; n++) {
      curlen = nextlen; nextlen = tree[(n + 1) * 2 + 1];
      if (++count < max_count && curlen == nextlen) {
        continue;
      } else if (count < min_count) {
        do {
          _sendCode(curlen, _bitLengthTree);
        } while (--count != 0);
      } else if (curlen != 0) {
        if (curlen != prevlen) {
          _sendCode(curlen, _bitLengthTree);
          count--;
        }
        _sendCode(REP_3_6, _bitLengthTree);
        _sendBits(count - 3, 2);
      } else if (count <= 10) {
        _sendCode(REPZ_3_10, _bitLengthTree);
        _sendBits(count - 3, 3);
      } else {
        _sendCode(REPZ_11_138, _bitLengthTree);
        _sendBits(count - 11, 7);
      }
      count = 0;
      prevlen = curlen;
      if (nextlen == 0) {
        max_count = 138;
        min_count = 3;
      } else if (curlen == nextlen) {
        max_count = 6;
        min_count = 3;
      } else {
        max_count = 7;
        min_count = 4;
      }
    }
  }

  /**
   * Output a byte on the stream.
   * IN assertion: there is enough room in pending_buf.
   */
  void _putBytes(Uint8List p, int start, int len) {
    if (len == 0) {
      return;
    }
    _pendingBuffer.setRange(_pending, _pending + len, p, start);
    _pending += len;
  }

  void _putByte(int c) {
    _pendingBuffer[_pending++] = c;
  }

  void _putShort(int w) {
    _putByte((w));
    _putByte((_rshift(w, 8)));
  }

  void _sendCode(int c, List<int> tree) {
    _sendBits((tree[c * 2] & 0xffff), (tree[c * 2 + 1] & 0xffff));
  }

  void _sendBits(int value_Renamed, int length) {
    int len = length;
    if (_numValidBits > BUF_SIZE - len) {
      int val = value_Renamed;
      _bitBuffer = (_bitBuffer | (((val << _numValidBits) & 0xffff)));
      _putShort(_bitBuffer);
      _bitBuffer = (_rshift(val, (BUF_SIZE - _numValidBits)));
      _numValidBits += len - BUF_SIZE;
    } else {
      _bitBuffer = (_bitBuffer | ((((value_Renamed) << _numValidBits) & 0xffff)));
      _numValidBits += len;
    }
  }

  /**
   * Send one empty static block to give enough lookahead for inflate.
   * This takes 10 bits, of which 7 may remain in the bit buffer.
   * The current inflate code requires 9 bits of lookahead. If the
   * last two codes for the previous block (real code plus EOB) were coded
   * on 5 bits or less, inflate may have only 5+3 bits of lookahead to decode
   * the last real code. In this case we send two empty static blocks instead
   * of one. (There are no problems if the previous block is stored or fixed.)
   * To simplify the code, we assume the worst case of last real code encoded
   * on one bit only.
   */
  void _trAlign() {
    _sendBits(STATIC_TREES << 1, 3);
    _sendCode(END_BLOCK, _StaticTree.STATIC_LTREE);

    biFlush();

    // Of the 10 bits for the empty block, we have already sent
    // (10 - bi_valid) bits. The lookahead for the last real code (before
    // the EOB of the previous block) was thus at least one plus the length
    // of the EOB plus what we have just sent of the empty static block.
    if (1 + _lastEOBLen + 10 - _numValidBits < 9) {
      _sendBits(STATIC_TREES << 1, 3);
      _sendCode(END_BLOCK, _StaticTree.STATIC_LTREE);
      biFlush();
    }

    _lastEOBLen = 7;
  }


  /**
   * Save the match info and tally the frequency counts. Return true if
   * the current block must be flushed.
   */
  bool _trTally(int dist, int lc) {
    _pendingBuffer[_dbuf + _lastLit * 2] = (_rshift(dist, 8));
    _pendingBuffer[_dbuf + _lastLit * 2 + 1] = dist;

    _pendingBuffer[_lbuf + _lastLit] = lc;
    _lastLit++;

    if (dist == 0) {
      // lc is the unmatched char
      _dynamicLengthTree[lc * 2]++;
    } else {
      _matches++;
      // Here, lc is the match length - MIN_MATCH
      dist--; // dist = match distance - 1
      _dynamicLengthTree[(_HuffmanTree.LENGTH_CODE[lc] + LITERALS + 1) * 2]++;
      _dynamicDistTree[_HuffmanTree._dCode(dist) * 2]++;
    }

    if ((_lastLit & 0x1fff) == 0 && _level > 2) {
      // Compute an upper bound for the compressed length
      int out_length = _lastLit * 8;
      int in_length = _strStart - _blockStart;
      int dcode;
      for (dcode = 0; dcode < D_CODES; dcode++) {
        out_length = (out_length + _dynamicDistTree[dcode * 2] * (5 + _HuffmanTree.EXTRA_D_BITS[dcode]));
      }
      out_length = _rshift(out_length, 3);
      if ((_matches < (_lastLit / 2)) && out_length < in_length / 2) {
        return true;
      }
    }

    return (_lastLit == _litBufferSize - 1);
    // We avoid equality with lit_bufsize because of wraparound at 64K
    // on 16 bit machines and because stored blocks are restricted to
    // 64K-1 bytes.
  }

  /**
   * Send the block data compressed using the given Huffman trees
   */
  void _compressBlock(List<int> ltree, List<int> dtree) {
    int dist; // distance of matched string
    int lc; // match length or unmatched char (if dist == 0)
    int lx = 0; // running index in l_buf
    int code; // the code to send
    int extra; // number of extra bits to send

    if (_lastLit != 0) {
      do {
        dist = ((_pendingBuffer[_dbuf + lx * 2] << 8) & 0xff00) |
                (_pendingBuffer[_dbuf + lx * 2 + 1] & 0xff);
        lc = (_pendingBuffer[_lbuf + lx]) & 0xff;
        lx++;

        if (dist == 0) {
          _sendCode(lc, ltree); // send a literal byte
        } else {
          // Here, lc is the match length - MIN_MATCH
          code = _HuffmanTree.LENGTH_CODE[lc];

          _sendCode(code + LITERALS + 1, ltree); // send the length code
          extra = _HuffmanTree.EXTRA_L_BITS[code];
          if (extra != 0) {
            lc -= _HuffmanTree.BASE_LENGTH[code];
            _sendBits(lc, extra); // send the extra length bits
          }
          dist--; // dist is now the match distance - 1
          code = _HuffmanTree._dCode(dist);

          _sendCode(code, dtree); // send the distance code
          extra = _HuffmanTree.EXTRA_D_BITS[code];
          if (extra != 0) {
            dist -= _HuffmanTree.BASE_DIST[code];
            _sendBits(dist, extra); // send the extra distance bits
          }
        } // literal or match pair ?

        // Check that the overlay between pending_buf and d_buf+l_buf is ok:
      } while (lx < _lastLit);
    }

    _sendCode(END_BLOCK, ltree);
    _lastEOBLen = ltree[END_BLOCK * 2 + 1];
  }

  /**
   * Set the data type to ASCII or BINARY, using a crude approximation:
   * binary if more than 20% of the bytes are <= 6 or >= 128, ascii otherwise.
   * IN assertion: the fields freq of dyn_ltree are set and the total of all
   * frequencies does not exceed 64K (to fit in an int on 16 bit machines).
   */
  void setDataType() {
    int n = 0;
    int ascii_freq = 0;
    int bin_freq = 0;
    while (n < 7) {
      bin_freq += _dynamicLengthTree[n * 2]; n++;
    }
    while (n < 128) {
      ascii_freq += _dynamicLengthTree[n * 2]; n++;
    }
    while (n < LITERALS) {
      bin_freq += _dynamicLengthTree[n * 2]; n++;
    }
    _dataType = (bin_freq > (_rshift(ascii_freq, 2)) ?
                Z_BINARY : Z_ASCII);
  }

  /**
   * Flush the bit buffer, keeping at most 7 bits in it.
   */
  void biFlush() {
    if (_numValidBits == 16) {
      _putShort(_bitBuffer);
      _bitBuffer = 0;
      _numValidBits = 0;
    } else if (_numValidBits >= 8) {
      _putByte(_bitBuffer);
      _bitBuffer = (_rshift(_bitBuffer, 8));
      _numValidBits -= 8;
    }
  }

  /**
   * Flush the bit buffer and align the output on a byte boundary
   */
  void _biWindup() {
    if (_numValidBits > 8) {
      _putShort(_bitBuffer);
    } else if (_numValidBits > 0) {
      _putByte(_bitBuffer);
    }
    _bitBuffer = 0;
    _numValidBits = 0;
  }

  /**
   * Copy a stored block, storing first the length and its
   * one's complement if requested.
   */
  void _copyBlock(int buf, int len, bool header) {
    _biWindup(); // align on byte boundary
    _lastEOBLen = 8; // enough lookahead for inflate

    if (header) {
      _putShort(len);
      _putShort((~len + 0x10000) & 0xffff);
    }

    _putBytes(_window, buf, len);
  }

  void _flushBlockOnly(bool eof) {
    _trFlushBlock(_blockStart >= 0 ? _blockStart : -1,
                  _strStart - _blockStart, eof);
    _blockStart = _strStart;
    _flushPending();
  }

  /**
   * Copy without compression as much as possible from the input stream, return
   * the current block state.
   * This function does not insert new strings in the dictionary since
   * uncompressible data is probably not useful. This function is used
   * only for the level=0 compression option.
   * NOTE: this function should be optimized to avoid extra copying from
   * window to pending_buf.
   */
  int _deflateStored(int flush) {
    // Stored blocks are limited to 0xffff bytes, pending_buf is limited
    // to pending_buf_size, and each stored block has a 5 byte header:
    int maxBlockSize = 0xffff;

    if (maxBlockSize > _pendingBufferSize - 5) {
      maxBlockSize = _pendingBufferSize - 5;
    }

    // Copy as much as possible from input to output:
    while (true) {
      // Fill the window as much as possible:
      if (_lookAhead <= 1) {
        _fillWindow();

        if (_lookAhead == 0 && flush == NO_FLUSH) {
          return NEED_MORE;
        }

        if (_lookAhead == 0) {
          break; // flush the current block
        }
      }

      _strStart += _lookAhead;
      _lookAhead = 0;

      // Emit a stored block if pendingBuffer will be full:
      int maxStart = _blockStart + maxBlockSize;

      if (_strStart >= maxStart) {
        _lookAhead = (_strStart - maxStart);
        _strStart = maxStart;
        _flushBlockOnly(false);
      }

      // Flush if we may have to slide, otherwise block_start may become
      // negative and the data will be gone:
      if (_strStart - _blockStart >= _windowSize - MIN_LOOKAHEAD) {
        _flushBlockOnly(false);
      }
    }

    _flushBlockOnly(flush == FINISH);

    return (flush == FINISH) ? FINISH_DONE : BLOCK_DONE;
  }

  /**
   * Send a stored block
   */
  void _trStoredBlock(int buf, int storedLen, bool eof) {
    _sendBits((STORED_BLOCK << 1) + (eof ? 1 : 0), 3); // send block type
    _copyBlock(buf, storedLen, true); // with header
  }

  /**
   * Determine the best encoding for the current block: dynamic trees, static
   * trees or store, and output the encoded block to the zip file.
   */
  void _trFlushBlock(int buf, int storedLen, bool eof) {
    int optLenb;
    int staticLenb;
    int max_blindex = 0; // index of last bit length code of non zero freq

    // Build the Huffman trees unless a stored block is forced
    if (_level > 0) {
      // Check if the file is ascii or binary
      if (_dataType == Z_UNKNOWN) {
        setDataType();
      }

      // Construct the literal and distance trees
      _lDesc._buildTree(this);

      _dDesc._buildTree(this);

      // At this point, opt_len and static_len are the total bit lengths of
      // the compressed block data, excluding the tree representations.

      // Build the bit length tree for the above two trees, and get the index
      // in bl_order of the last bit length code to send.
      max_blindex = _buildBitLengthTree();

      // Determine the best encoding. Compute first the block length in bytes
      optLenb = _rshift((_optimalLen + 3 + 7), 3);
      staticLenb = _rshift((_staticLen + 3 + 7), 3);

      if (staticLenb <= optLenb) {
        optLenb = staticLenb;
      }
    } else {
      optLenb = staticLenb = storedLen + 5; // force a stored block
    }

    if (storedLen + 4 <= optLenb && buf != -1) {
      // 4: two words for the lengths
      // The test buf != NULL is only necessary if LIT_BUFSIZE > WSIZE.
      // Otherwise we can't have processed more than WSIZE input bytes since
      // the last block flush, because compression would have been
      // successful. If LIT_BUFSIZE <= WSIZE, it is never too late to
      // transform a block into a stored block.
      _trStoredBlock(buf, storedLen, eof);
    } else if (staticLenb == optLenb) {
      _sendBits((STATIC_TREES << 1) + (eof ? 1 : 0), 3);
      _compressBlock(_StaticTree.STATIC_LTREE, _StaticTree.STATIC_DTREE);
    } else {
      _sendBits((DYN_TREES << 1) + (eof ? 1 : 0), 3);
      _sendAllTrees(_lDesc.maxCode + 1, _dDesc.maxCode + 1, max_blindex + 1);
      _compressBlock(_dynamicLengthTree, _dynamicDistTree);
    }

    // The above check is made mod 2^32, for files larger than 512 MB
    // and uLong implemented on 32 bits.

    _initBlock();

    if (eof) {
      _biWindup();
    }
  }

  /**
   * Fill the window when the lookahead becomes insufficient.
   * Updates strstart and lookahead.
   * IN assertion: lookahead < MIN_LOOKAHEAD
   * OUT assertions: strstart <= window_size-MIN_LOOKAHEAD
   *    At least one byte has been read, or avail_in == 0; reads are
   *    performed for at least two bytes (required for the zip translate_eol
   *    option -- not supported here).
   */
  void _fillWindow() {
    do {
      // Amount of free space at the end of the window.
      int more = (_actualWindowSize - _lookAhead - _strStart);

      // Deal with 64K limit:
      if (more == 0 && _strStart == 0 && _lookAhead == 0) {
        more = _windowSize;
      } else if (_strStart >= _windowSize + _windowSize - MIN_LOOKAHEAD) {
        // If the window is almost full and there is insufficient lookahead,
        // move the upper half to the lower one to make room in the upper half.

        _window.setRange(0, _windowSize, _window, _windowSize);

        _matchStart -= _windowSize;
        _strStart -= _windowSize; // we now have strstart >= MAX_DIST
        _blockStart -= _windowSize;

        // Slide the hash table (could be avoided with 32 bit values
        // at the expense of memory usage). We slide even when level == 0
        // to keep the hash table consistent if we switch back to level > 0
        // later. (Using level 0 permanently is not an optimal usage of
        // zlib, so we don't care about this pathological case.)

        int n = _hashSize;
        int p = n;
        do {
          int m = (_head[--p] & 0xffff);
          _head[p] = (m >= _windowSize?(m - _windowSize) : 0);
        } while (--n != 0);

        n = _windowSize;
        p = n;
        do {
          int m = (_prev[--p] & 0xffff);
          _prev[p] = (m >= _windowSize ? (m - _windowSize) : 0);
          // If n is not on any hash chain, prev[n] is garbage but
          // its value will never be used.
        } while (--n != 0);

        more += _windowSize;
      }

      if (_input.isEOS) {
        return;
      }

      // If there was no sliding:
      //    strstart <= WSIZE+MAX_DIST-1 && lookahead <= MIN_LOOKAHEAD - 1 &&
      //    more == window_size - lookahead - strstart
      // => more >= window_size - (MIN_LOOKAHEAD-1 + WSIZE + MAX_DIST-1)
      // => more >= window_size - 2*WSIZE + 2
      // In the BIG_MEM or MMAP case (not yet supported),
      //   window_size == input_size + MIN_LOOKAHEAD  &&
      //   strstart + s->lookahead <= input_size => more >= MIN_LOOKAHEAD.
      // Otherwise, window_size == 2*WSIZE so more >= 2.
      // If there was sliding, more >= WSIZE. So in all cases, more >= 2.

      int n = _readBuf(_window, _strStart + _lookAhead, more);
      _lookAhead += n;

      // Initialize the hash value now that we have some input:
      if (_lookAhead >= MIN_MATCH) {
        _insertHash = _window[_strStart] & 0xff;
        _insertHash = (((_insertHash) << _hashShift) ^
                 (_window[_strStart + 1] & 0xff)) & _hashMask;
      }

      // If the whole input has less than MIN_MATCH bytes, ins_h is garbage,
      // but this is not important since only literal bytes will be emitted.
    } while (_lookAhead < MIN_LOOKAHEAD && !_input.isEOS);
  }

  /**
   * Compress as much as possible from the input stream, return the current
   * block state.
   * This function does not perform lazy evaluation of matches and inserts
   * new strings in the dictionary only for unmatched strings or for short
   * matches. It is used only for the fast compression options.
   */
  int _deflateFast(int flush) {
    int hash_head = 0; // head of the hash chain
    bool bflush; // set if current block must be flushed

    while (true) {
      // Make sure that we always have enough lookahead, except
      // at the end of the input file. We need MAX_MATCH bytes
      // for the next match, plus MIN_MATCH bytes to insert the
      // string following the next match.
      if (_lookAhead < MIN_LOOKAHEAD) {
        _fillWindow();
        if (_lookAhead < MIN_LOOKAHEAD && flush == NO_FLUSH) {
          return NEED_MORE;
        }
        if (_lookAhead == 0) {
          break; // flush the current block
        }
      }

      // Insert the string window[strstart .. strstart+2] in the
      // dictionary, and set hash_head to the head of the hash chain:
      if (_lookAhead >= MIN_MATCH) {
        _insertHash = (((_insertHash) << _hashShift) ^
                 (_window[(_strStart) + (MIN_MATCH - 1)] & 0xff)) & _hashMask;

        hash_head = (_head[_insertHash] & 0xffff);
        _prev[_strStart & _windowMask] = _head[_insertHash];
        _head[_insertHash] = _strStart;
      }

      // Find the longest match, discarding those <= prev_length.
      // At this point we have always match_length < MIN_MATCH

      if (hash_head != 0 &&
          ((_strStart - hash_head) & 0xffff) <= _windowSize - MIN_LOOKAHEAD) {
        // To simplify the code, we prevent matches with the string
        // of window index 0 (in particular we have to avoid a match
        // of the string with itself at the start of the input file).
        if (_strategy != Z_HUFFMAN_ONLY) {
          _matchLength = _longestMatch(hash_head);
        }

        // longest_match() sets match_start
      }

      if (_matchLength >= MIN_MATCH) {
        bflush = _trTally(_strStart - _matchStart, _matchLength - MIN_MATCH);

        _lookAhead -= _matchLength;

        // Insert new strings in the hash table only if the match length
        // is not too large. This saves time but degrades compression.
        if (_matchLength <= _config.maxLazy && _lookAhead >= MIN_MATCH) {
          _matchLength--; // string at strstart already in hash table
          do {
            _strStart++;

            _insertHash = ((_insertHash << _hashShift) ^
                           (_window[(_strStart) + (MIN_MATCH - 1)] & 0xff)) &
                           _hashMask;

            hash_head = (_head[_insertHash] & 0xffff);
            _prev[_strStart & _windowMask] = _head[_insertHash];
            _head[_insertHash] = _strStart;

            // strstart never exceeds WSIZE-MAX_MATCH, so there are
            // always MIN_MATCH bytes ahead.
          } while (--_matchLength != 0);
          _strStart++;
        } else {
          _strStart += _matchLength;
          _matchLength = 0;
          _insertHash = _window[_strStart] & 0xff;

          _insertHash = (((_insertHash) << _hashShift) ^
                         (_window[_strStart + 1] & 0xff)) & _hashMask;
          // If lookahead < MIN_MATCH, ins_h is garbage, but it does not
          // matter since it will be recomputed at next deflate call.
        }
      } else {
        // No match, output a literal byte

        bflush = _trTally(0, _window[_strStart] & 0xff);
        _lookAhead--;
        _strStart++;
      }

      if (bflush) {
        _flushBlockOnly(false);
      }
    }

    _flushBlockOnly(flush == FINISH);

    return flush == FINISH ? FINISH_DONE : BLOCK_DONE;
  }

  /**
   * Same as above, but achieves better compression. We use a lazy
   * evaluation for matches: a match is finally adopted only if there is
   * no better match at the next window position.
   */
  int _deflateSlow(int flush) {
    int hash_head = 0; // head of hash chain
    bool bflush; // set if current block must be flushed

    // Process the input block.
    while (true) {
      // Make sure that we always have enough lookahead, except
      // at the end of the input file. We need MAX_MATCH bytes
      // for the next match, plus MIN_MATCH bytes to insert the
      // string following the next match.
      if (_lookAhead < MIN_LOOKAHEAD) {
        _fillWindow();

        if (_lookAhead < MIN_LOOKAHEAD && flush == NO_FLUSH) {
          return NEED_MORE;
        }

        if (_lookAhead == 0) {
          break; // flush the current block
        }
      }

      // Insert the string window[strstart .. strstart+2] in the
      // dictionary, and set hash_head to the head of the hash chain:

      if (_lookAhead >= MIN_MATCH) {
        _insertHash = (((_insertHash) << _hashShift) ^
                 (_window[(_strStart) + (MIN_MATCH - 1)] & 0xff)) & _hashMask;
        hash_head = (_head[_insertHash] & 0xffff);
        _prev[_strStart & _windowMask] = _head[_insertHash];
        _head[_insertHash] = _strStart;
      }

      // Find the longest match, discarding those <= prev_length.
      _prevLength = _matchLength;
      _prevMatch = _matchStart;
      _matchLength = MIN_MATCH - 1;

      if (hash_head != 0 && _prevLength < _config.maxLazy &&
          ((_strStart - hash_head) & 0xffff) <= _windowSize - MIN_LOOKAHEAD) {
        // To simplify the code, we prevent matches with the string
        // of window index 0 (in particular we have to avoid a match
        // of the string with itself at the start of the input file).

        if (_strategy != Z_HUFFMAN_ONLY) {
          _matchLength = _longestMatch(hash_head);
        }
        // longest_match() sets match_start

        if (_matchLength <= 5 &&
            (_strategy == Z_FILTERED ||
             (_matchLength == MIN_MATCH && _strStart - _matchStart > 4096))) {
          // If prev_match is also MIN_MATCH, match_start is garbage
          // but we will ignore the current match anyway.
          _matchLength = MIN_MATCH - 1;
        }
      }

      // If there was a match at the previous step and the current
      // match is not better, output the previous match:
      if (_prevLength >= MIN_MATCH && _matchLength <= _prevLength) {
        int max_insert = _strStart + _lookAhead - MIN_MATCH;
        // Do not insert strings in hash table beyond this.

        bflush = _trTally(_strStart - 1 - _prevMatch, _prevLength - MIN_MATCH);

        // Insert in hash table all strings up to the end of the match.
        // strstart-1 and strstart are already inserted. If there is not
        // enough lookahead, the last two strings are not inserted in
        // the hash table.
        _lookAhead -= (_prevLength - 1);
        _prevLength -= 2;

        do {
          if (++_strStart <= max_insert) {
            _insertHash = (((_insertHash) << _hashShift) ^
                     (_window[(_strStart) + (MIN_MATCH - 1)] & 0xff)) & _hashMask;
            hash_head = (_head[_insertHash] & 0xffff);
            _prev[_strStart & _windowMask] = _head[_insertHash];
            _head[_insertHash] = _strStart;
          }
        } while (--_prevLength != 0);

        _matchAvailable = 0;
        _matchLength = MIN_MATCH - 1;
        _strStart++;

        if (bflush) {
          _flushBlockOnly(false);
        }
      } else if (_matchAvailable != 0) {

        // If there was no match at the previous position, output a
        // single literal. If there was a match but the current match
        // is longer, truncate the previous match to a single literal.

        bflush = _trTally(0, _window[_strStart - 1] & 0xff);

        if (bflush) {
          _flushBlockOnly(false);
        }
        _strStart++;
        _lookAhead--;
      } else {
        // There is no previous match to compare with, wait for
        // the next step to decide.
        _matchAvailable = 1;
        _strStart++;
        _lookAhead--;
      }
    }

    if (_matchAvailable != 0) {
      bflush = _trTally(0, _window[_strStart - 1] & 0xff);
      _matchAvailable = 0;
    }
    _flushBlockOnly(flush == FINISH);

    return flush == FINISH ? FINISH_DONE : BLOCK_DONE;
  }

  int _longestMatch(int cur_match) {
    int chain_length = _config.maxChain; // max hash chain length
    int scan = _strStart; // current string
    int match; // matched string
    int len; // length of current match
    int best_len = _prevLength; // best match length so far
    int limit = _strStart > (_windowSize - MIN_LOOKAHEAD) ?
                _strStart - (_windowSize - MIN_LOOKAHEAD) : 0;
    int nice_match = _config.niceLength;

    // Stop when cur_match becomes <= limit. To simplify the code,
    // we prevent matches with the string of window index 0.

    int wmask = _windowMask;

    int strend = _strStart + MAX_MATCH;
    int scan_end1 = _window[scan + best_len - 1];
    int scan_end = _window[scan + best_len];

    // The code is optimized for HASH_BITS >= 8 and MAX_MATCH-2 multiple of 16.
    // It is easy to get rid of this optimization if necessary.

    // Do not waste too much time if we already have a good match:
    if (_prevLength >= _config.goodLength) {
      chain_length >>= 2;
    }

    // Do not look for matches beyond the end of the input. This is necessary
    // to make deflate deterministic.
    if (nice_match > _lookAhead) {
      nice_match = _lookAhead;
    }

    do {
      match = cur_match;

      // Skip to next match if the match length cannot increase
      // or if the match length is less than 2:
      if (_window[match + best_len] != scan_end ||
          _window[match + best_len - 1] != scan_end1 ||
          _window[match] != _window[scan] ||
          _window[++match] != _window[scan + 1]) {
        continue;
      }

      // The check at best_len-1 can be removed because it will be made
      // again later. (This heuristic is not always a win.)
      // It is not necessary to compare scan[2] and match[2] since they
      // are always equal when the other bytes match, given that
      // the hash keys are equal and that HASH_BITS >= 8.
      scan += 2;
      match++;

      // We check for insufficient lookahead only every 8th comparison;
      // the 256th check will be made at strstart+258.
      do {
      } while (_window[++scan] == _window[++match] &&
               _window[++scan] == _window[++match] &&
               _window[++scan] == _window[++match] &&
               _window[++scan] == _window[++match] &&
               _window[++scan] == _window[++match] &&
               _window[++scan] == _window[++match] &&
               _window[++scan] == _window[++match] &&
               _window[++scan] == _window[++match] &&
               scan < strend);

      len = MAX_MATCH - (strend - scan);
      scan = strend - MAX_MATCH;

      if (len > best_len) {
        _matchStart = cur_match;
        best_len = len;
        if (len >= nice_match) {
          break;
        }
        scan_end1 = _window[scan + best_len - 1];
        scan_end = _window[scan + best_len];
      }
    } while ((cur_match = (_prev[cur_match & wmask] & 0xffff)) > limit &&
              --chain_length != 0);

    if (best_len <= _lookAhead) {
      return best_len;
    }

    return _lookAhead;
  }

  /**
   * Read a new buffer from the current input stream, update the adler32
   * and total number of bytes read.  All deflate() input goes through
   * this function so some applications may wish to modify it to avoid
   * allocating a large strm->next_in buffer and copying from it.
   * (See also flush_pending()).
   */
  int total = 0;
  int _readBuf(Uint8List buf, int start, int size) {
    if (size == 0 || _input.isEOS) {
      return 0;
    }

    InputStream data = _input.readBytes(size);
    int len = data.length;
    if (len == 0) {
      return 0;
    }

    Uint8List bytes = data.toUint8List();
    if (len > bytes.length) {
      len = bytes.length;
    }
    buf.setRange(start, start + len, bytes);
    total += len;
    crc32 = getCrc32(bytes, crc32);

    return len;
  }

  /**
   * Flush as much pending output as possible. All deflate() output goes
   * through this function so some applications may wish to modify it
   * to avoid allocating a large strm->next_out buffer and copying into it.
   */
  void _flushPending() {
    int len = _pending;
    _output.writeBytes(_pendingBuffer, len);

    _pendingOut += len;
    _pending -= len;
    if (_pending == 0) {
      _pendingOut = 0;
    }
  }

  _DeflaterConfig _getConfig(int level) {
    switch (level) {
      //                             good  lazy  nice  chain
      case 0: return new _DeflaterConfig(0, 0, 0, 0, STORED);
      case 1: return new _DeflaterConfig(4, 4, 8, 4, FAST);
      case 2: return new _DeflaterConfig(4, 5, 16, 8, FAST);
      case 3: return new _DeflaterConfig(4, 6, 32, 32, FAST);

      case 4: return new _DeflaterConfig(4, 4, 16, 16, SLOW);
      case 5: return new _DeflaterConfig(8, 16, 32, 32, SLOW);
      case 6: return new _DeflaterConfig(8, 16, 128, 128, SLOW);
      case 7: return new _DeflaterConfig(8, 32, 128, 256, SLOW);
      case 8: return new _DeflaterConfig(32, 128, 258, 1024, SLOW);
      case 9: return new _DeflaterConfig(32, 258, 258, 4096, SLOW);
    }
    return null;
  }

  static const int MAX_MEM_LEVEL = 9;

  static const int Z_DEFAULT_COMPRESSION = - 1;

  /// 32K LZ77 window
  static const int MAX_WBITS = 15;
  static const int DEF_MEM_LEVEL = 8;

  static const int STORED = 0;
  static const int FAST = 1;
  static const int SLOW = 2;
  static _DeflaterConfig _config;

  /// block not completed, need more input or more output
  static const int NEED_MORE = 0;

  /// block flush performed
  static const int BLOCK_DONE = 1;

  /// finish started, need only more output at next deflate
  static const int FINISH_STARTED = 2;

  /// finish done, accept no more input or output
  static const int FINISH_DONE = 3;

  static const int Z_FILTERED = 1;
  static const int Z_HUFFMAN_ONLY = 2;
  static const int Z_DEFAULT_STRATEGY = 0;

  static const int Z_OK = 0;
  static const int Z_STREAM_END = 1;
  static const int Z_NEED_DICT = 2;
  static const int Z_ERRNO = - 1;
  static const int Z_STREAM_ERROR = - 2;
  static const int Z_DATA_ERROR = - 3;
  static const int Z_MEM_ERROR = - 4;
  static const int Z_BUF_ERROR = - 5;
  static const int Z_VERSION_ERROR = - 6;

  static const int INIT_STATE = 42;
  static const int BUSY_STATE = 113;
  static const int FINISH_STATE = 666;

  /// The deflate compression method
  static const int Z_DEFLATED = 8;

  static const int STORED_BLOCK = 0;
  static const int STATIC_TREES = 1;
  static const int DYN_TREES = 2;

  // The three kinds of block type
  static const int Z_BINARY = 0;
  static const int Z_ASCII = 1;
  static const int Z_UNKNOWN = 2;

  static const int BUF_SIZE = 8 * 2;

  /// repeat previous bit length 3-6 times (2 bits of repeat count)
  static const int REP_3_6 = 16;

  /// repeat a zero length 3-10 times  (3 bits of repeat count)
  static const int REPZ_3_10 = 17;

  /// repeat a zero length 11-138 times  (7 bits of repeat count)
  static const int REPZ_11_138 = 18;

  static const int MIN_MATCH = 3;
  static const int MAX_MATCH = 258;
  static const int MIN_LOOKAHEAD = (MAX_MATCH + MIN_MATCH + 1);

  static const int MAX_BITS = 15;
  static const int D_CODES = 30;
  static const int BL_CODES = 19;
  static const int LENGTH_CODES = 29;
  static const int LITERALS = 256;
  static const int L_CODES = (LITERALS + 1 + LENGTH_CODES);
  static const int HEAP_SIZE = (2 * L_CODES + 1);

  static const int END_BLOCK = 256;

  dynamic _input;
  dynamic _output;

  int _status;
  /// output still pending
  Uint8List _pendingBuffer;
  /// size of pending_buf
  int _pendingBufferSize;
  /// next pending byte to output to the stream
  int _pendingOut; // ignore: unused_field
  /// nb of bytes in the pending buffer
  int _pending;
  /// UNKNOWN, BINARY or ASCII
  int _dataType;
  /// STORED (for zip only) or DEFLATED
  int _method; // ignore: unused_field
  /// value of flush param for previous deflate call
  int _lastFlush; // ignore: unused_field

  /// LZ77 window size (32K by default)
  int _windowSize;
  /// log2(w_size)  (8..16)
  int _windowBits;
  /// w_size - 1
  int _windowMask;

  /// Sliding window. Input bytes are read into the second half of the window,
  /// and move to the first half later to keep a dictionary of at least wSize
  /// bytes. With this organization, matches are limited to a distance of
  /// wSize-MAX_MATCH bytes, but this ensures that IO is always
  /// performed with a length multiple of the block size. Also, it limits
  /// the window size to 64K, which is quite useful on MSDOS.
  /// To do: use the user input buffer as sliding window.
  Uint8List _window;

  /// Actual size of window: 2*wSize, except when the user input buffer
  /// is directly used as sliding window.
  int _actualWindowSize;

  /// Link to older string with same hash index. To limit the size of this
  /// array to 64K, this link is maintained only for the last 32K strings.
  /// An index in this array is thus a window index modulo 32K.
  Uint16List _prev;

  /// Heads of the hash chains or NIL.
  Uint16List _head;

  /// hash index of string to be inserted
  int _insertHash;
  /// number of elements in hash table
  int _hashSize;
  /// log2(hash_size)
  int _hashBits;
  /// hash_size-1
  int _hashMask;

  /// Number of bits by which ins_h must be shifted at each input
  /// step. It must be such that after MIN_MATCH steps, the oldest
  /// byte no longer takes part in the hash key, that is:
  /// hash_shift * MIN_MATCH >= hash_bits
  int _hashShift;

  /// Window position at the beginning of the current output block. Gets
  /// negative when the window is moved backwards.
  int _blockStart;

  /// length of best match
  int _matchLength;
  /// previous match
  int _prevMatch;
  /// set if previous match exists
  int _matchAvailable;
  /// start of string to insert
  int _strStart;
  /// start of matching string
  int _matchStart = 0;
  /// number of valid bytes ahead in window
  int _lookAhead;

  /// Length of the best match at previous step. Matches not greater than this
  /// are discarded. This is used in the lazy match evaluation.
  int _prevLength;

  // Insert new strings in the hash table only if the match length is not
  // greater than this length. This saves time but degrades compression.
  // max_insert_length is used only for compression levels <= 3.

  /// compression level (1..9)
  int _level;
  /// favor or force Huffman coding
  int _strategy;

  /// literal and length tree
  Uint16List _dynamicLengthTree;
  /// distance tree
  Uint16List _dynamicDistTree;
  /// Huffman tree for bit lengths
  Uint16List _bitLengthTree;

  /// desc for literal tree
  _HuffmanTree _lDesc = new _HuffmanTree();
  /// desc for distance tree
  _HuffmanTree _dDesc = new _HuffmanTree();
  /// desc for bit length tree
  _HuffmanTree _blDesc = new _HuffmanTree();

  /// number of codes at each bit length for an optimal tree
  Uint16List _bitLengthCount = new Uint16List(MAX_BITS + 1);

  /// heap used to build the Huffman trees
  Uint32List _heap = new Uint32List(2 * L_CODES + 1);

  /// number of elements in the heap
  int _heapLen;
  /// element of largest frequency
  int _heapMax;
  // The sons of heap[n] are heap[2*n] and heap[2*n+1]. heap[0] is not used.
  // The same heap array is used to build all trees.

  /// Depth of each subtree used as tie breaker for trees of equal frequency
  Uint8List _depth = new Uint8List(2 * L_CODES + 1);

  /// index for literals or lengths
  int _lbuf;

  /// Size of match buffer for literals/lengths.  There are 4 reasons for
  /// limiting lit_bufsize to 64K:
  ///   - frequencies can be kept in 16 bit counters
  ///   - if compression is not successful for the first block, all input
  ///     data is still in the window so we can still emit a stored block even
  ///     when input comes from standard input.  (This can also be done for
  ///     all blocks if lit_bufsize is not greater than 32K.)
  ///   - if compression is not successful for a file smaller than 64K, we can
  ///     even emit a stored file instead of a stored block (saving 5 bytes).
  ///     This is applicable only for zip (not gzip or zlib).
  ///   - creating new Huffman trees less frequently may not provide fast
  ///     adaptation to changes in the input data statistics. (Take for
  ///     example a binary file with poorly compressible code followed by
  ///     a highly compressible string table.) Smaller buffer sizes give
  ///     fast adaptation but have of course the overhead of transmitting
  ///     trees more frequently.
  ///   - I can't count above 4
  int _litBufferSize;

  /// running index in l_buf
  int _lastLit;

  // Buffer for distances. To simplify the code, d_buf and l_buf have
  // the same number of elements. To use different lengths, an extra flag
  // array would be necessary.

  /// index of pendig_buf
  int _dbuf;

  /// bit length of current block with optimal trees
  int _optimalLen;
  /// bit length of current block with static trees
  int _staticLen;
  /// number of string matches in current block
  int _matches;
  /// bit length of EOB code for last block
  int _lastEOBLen;

  /// Output buffer. bits are inserted starting at the bottom (least
  /// significant bits).
  int _bitBuffer;

  /// Number of valid bits in bi_buf.  All bits above the last valid bit
  /// are always zero.
  int _numValidBits;
}

class _DeflaterConfig {
  /// Use a faster search when the previous match is longer than this
  int goodLength;
  /// Attempt to find a better match only when the current match is strictly
  /// smaller than this value. This mechanism is used only for compression
  /// levels >= 4.
  int maxLazy;
  /// Stop searching when current match exceeds this
  int niceLength;
  /// To speed up deflation, hash chains are never searched beyond this
  /// length. A higher limit improves compression ratio but degrades the speed.
  int maxChain;
  /// STORED, FAST, or SLOW
  int function;

  _DeflaterConfig(this.goodLength, this.maxLazy, this.niceLength,
                  this.maxChain, this.function);
}

class _HuffmanTree {
  static const int MAX_BITS = 15;
  static const int BL_CODES = 19;
  static const int D_CODES = 30;
  static const int LITERALS = 256;
  static const int LENGTH_CODES = 29;
  static const int L_CODES = (LITERALS + 1 + LENGTH_CODES);
  static const int HEAP_SIZE = (2 * L_CODES + 1);

  /// Bit length codes must not exceed MAX_BL_BITS bits
  static const int MAX_BL_BITS = 7;

  /// end of block literal code
  static const int END_BLOCK = 256;

  /// repeat previous bit length 3-6 times (2 bits of repeat count)
  static const int REP_3_6 = 16;

  /// repeat a zero length 3-10 times  (3 bits of repeat count)
  static const int REPZ_3_10 = 17;

  /// repeat a zero length 11-138 times  (7 bits of repeat count)
  static const int REPZ_11_138 = 18;

  /// extra bits for each length code
  static const List<int> EXTRA_L_BITS = const [
      0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4,
      5, 5, 5, 5, 0];

  /// extra bits for each distance code
  static const List<int> EXTRA_D_BITS = const [
      0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10,
      11, 11, 12, 12, 13, 13];

  /// extra bits for each bit length code
  static const List<int> EXTRA_BL_BITS = const [
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 7];

  static const List<int> BL_ORDER = const [
      16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15];


  /// The lengths of the bit length codes are sent in order of decreasing
  /// probability, to avoid transmitting the lengths for unused bit
  /// length codes.
  static const int BUF_SIZE = 8 * 2;

  /// see definition of array dist_code below
  static const int DIST_CODE_LEN = 512;

  static const List<int> _DIST_CODE = const [
      0, 1, 2, 3, 4, 4, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8,
      9, 9, 9, 9, 9, 9, 9, 9, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
      10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
      12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 13, 13,
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
      13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 14, 14, 14, 14, 14, 14,
      14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
      14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
      14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
      14, 14, 14, 14, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
      15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
      15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
      15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 0, 0, 16, 17, 18,
      18, 19, 19, 20, 20, 20, 20, 21, 21, 21, 21, 22, 22, 22, 22, 22, 22, 22,
      22, 23, 23, 23, 23, 23, 23, 23, 23, 24, 24, 24, 24, 24, 24, 24, 24, 24,
      24, 24, 24, 24, 24, 24, 24, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26,
      26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26,
      26, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27,
      27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 28, 28, 28,
      28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28,
      28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28,
      28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28,
      28, 28, 28, 28, 28, 28, 28, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29,
      29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29,
      29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29,
      29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29];

  static const List<int> LENGTH_CODE = const [
      0, 1, 2, 3, 4, 5, 6, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 12, 12, 13,
      13, 13, 13, 14, 14, 14, 14, 15, 15, 15, 15, 16, 16, 16, 16, 16, 16, 16,
      16, 17, 17, 17, 17, 17, 17, 17, 17, 18, 18, 18, 18, 18, 18, 18, 18, 19,
      19, 19, 19, 19, 19, 19, 19, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20,
      20, 20, 20, 20, 20, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21,
      21, 21, 21, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22,
      22, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24,
      24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
      24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25, 25, 25, 25, 26, 26, 26, 26, 26, 26, 26, 26, 26,
      26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26,
      26, 26, 26, 26, 26, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27,
      27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27,
      28];

  static const List<int> BASE_LENGTH = const [
      0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16, 20, 24, 28, 32, 40, 48, 56,
      64, 80, 96, 112, 128, 160, 192, 224, 0];

  static const List<int> BASE_DIST = const [
      0, 1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 64, 96, 128, 192, 256, 384, 512,
      768, 1024, 1536, 2048, 3072, 4096, 6144, 8192, 12288, 16384, 24576];

  /// the dynamic tree
  Uint16List dynamicTree;
  /// largest code with non zero frequency
  int maxCode;
  /// the corresponding static tree
  _StaticTree staticDesc;

  /**
   * Compute the optimal bit lengths for a tree and update the total bit length
   * for the current block.
   * IN assertion: the fields freq and dad are set, heap[heap_max] and
   *    above are the tree nodes sorted by increasing frequency.
   * OUT assertions: the field len is set to the optimal bit length, the
   *     array bl_count contains the frequencies for each bit length.
   *     The length opt_len is updated; static_len is also updated if stree is
   *     not null.
   */
  void _genBitlen(Deflate s) {
    Uint16List tree = dynamicTree;
    List<int> stree = staticDesc.staticTree;
    List<int> extra = staticDesc.extraBits;
    int base_Renamed = staticDesc.extraBase;
    int max_length = staticDesc.maxLength;
    int h; // heap index
    int n, m; // iterate over the tree elements
    int bits; // bit length
    int xbits; // extra bits
    int f; // frequency
    int overflow = 0; // number of elements with bit length too large

    for (bits = 0; bits <= MAX_BITS; bits++) {
      s._bitLengthCount[bits] = 0;
    }

    // In a first pass, compute the optimal bit lengths (which may
    // overflow in the case of the bit length tree).
    tree[s._heap[s._heapMax] * 2 + 1] = 0; // root of the heap

    for (h = s._heapMax + 1; h < HEAP_SIZE; h++) {
      n = s._heap[h];
      bits = tree[tree[n * 2 + 1] * 2 + 1] + 1;
      if (bits > max_length) {
        bits = max_length;
        overflow++;
      }
      tree[n * 2 + 1] = bits;
      // We overwrite tree[n*2+1] which is no longer needed

      if (n > maxCode) {
        continue; // not a leaf node
      }

      s._bitLengthCount[bits]++;
      xbits = 0;
      if (n >= base_Renamed) {
        xbits = extra[n - base_Renamed];
      }
      f = tree[n * 2];
      s._optimalLen += f * (bits + xbits);
      if (stree != null) {
        s._staticLen += f * (stree[n * 2 + 1] + xbits);
      }
    }
    if (overflow == 0) {
      return ;
    }

    // This happens for example on obj2 and pic of the Calgary corpus
    // Find the first bit length which could increase:
    do {
      bits = max_length - 1;
      while (s._bitLengthCount[bits] == 0) {
        bits--;
      }
      s._bitLengthCount[bits]--; // move one leaf down the tree
      // move one overflow item as its brother
      s._bitLengthCount[bits + 1] = (s._bitLengthCount[bits + 1] + 2);
      s._bitLengthCount[max_length]--;
      // The brother of the overflow item also moves one step up,
      // but this does not affect bl_count[max_length]
      overflow -= 2;
    } while (overflow > 0);

    for (bits = max_length; bits != 0; bits--) {
      n = s._bitLengthCount[bits];
      while (n != 0) {
        m = s._heap[--h];
        if (m > maxCode) {
          continue;
        }
        if (tree[m * 2 + 1] != bits) {
          s._optimalLen = (s._optimalLen + (bits - tree[m * 2 + 1]) * tree[m * 2]);
          tree[m * 2 + 1] = bits;
        }
        n--;
      }
    }
  }

  /**
   * Construct one Huffman tree and assigns the code bit strings and lengths.
   * Update the total bit length for the current block.
   * IN assertion: the field freq is set for all tree elements.
   * OUT assertions: the fields len and code are set to the optimal bit length
   *     and corresponding code. The length opt_len is updated; static_len is
   *     also updated if stree is not null. The field max_code is set.
   */
  void _buildTree(Deflate s) {
    Uint16List tree = dynamicTree;
    List<int> stree = staticDesc.staticTree;
    int elems = staticDesc.numElements;
    int n, m; // iterate over heap elements
    int max_code = - 1; // largest code with non zero frequency
    int node; // new node being created

    // Construct the initial heap, with least frequent element in
    // heap[1]. The sons of heap[n] are heap[2*n] and heap[2*n+1].
    // heap[0] is not used.
    s._heapLen = 0;
    s._heapMax = HEAP_SIZE;

    for (n = 0; n < elems; n++) {
      if (tree[n * 2] != 0) {
        s._heap[++s._heapLen] = max_code = n;
        s._depth[n] = 0;
      } else {
        tree[n * 2 + 1] = 0;
      }
    }

    // The pkzip format requires that at least one distance code exists,
    // and that at least one bit should be sent even if there is only one
    // possible code. So to avoid special checks later on we force at least
    // two codes of non zero frequency.
    while (s._heapLen < 2) {
      node = s._heap[++s._heapLen] = (max_code < 2?++max_code:0);
      tree[node * 2] = 1;
      s._depth[node] = 0;
      s._optimalLen--;
      if (stree != null) {
        s._staticLen -= stree[node * 2 + 1];
      }
      // node is 0 or 1 so it does not have extra bits
    }
    this.maxCode = max_code;

    // The elements heap[heap_len/2+1 .. heap_len] are leaves of the tree,
    // establish sub-heaps of increasing lengths:

    for (n = s._heapLen ~/ 2; n >= 1; n--) {
      s._pqdownheap(tree, n);
    }

    // Construct the Huffman tree by repeatedly combining the least two
    // frequent nodes.

    node = elems; // next node of the tree
    do {
      // n = node of least frequency
      n = s._heap[1];
      s._heap[1] = s._heap[s._heapLen--];
      s._pqdownheap(tree, 1);
      m = s._heap[1]; // m = node of next least frequency

      s._heap[--s._heapMax] = n; // keep the nodes sorted by frequency
      s._heap[--s._heapMax] = m;

      // Create a new node father of n and m
      tree[node * 2] = (tree[n * 2] + tree[m * 2]);
      s._depth[node] = (_max(s._depth[n], s._depth[m]) + 1);
      tree[n * 2 + 1] = tree[m * 2 + 1] = node;

      // and insert the new node in the heap
      s._heap[1] = node++;
      s._pqdownheap(tree, 1);
    } while (s._heapLen >= 2);

    s._heap[--s._heapMax] = s._heap[1];

    // At this point, the fields freq and dad are set. We can now
    // generate the bit lengths.

    _genBitlen(s);

    // The field len is now set, we can generate the bit codes
    _genCodes(tree, max_code, s._bitLengthCount);
  }

  static int _max(int a, int b) => a > b ? a : b;

  /**
   * Generate the codes for a given tree and bit counts (which need not be
   * optimal).
   * IN assertion: the array bl_count contains the bit length statistics for
   * the given tree and the field len is set for all tree elements.
   * OUT assertion: the field code is set for all tree elements of non
   *     zero code length.
   */
  static void  _genCodes(Uint16List tree, int max_code, Uint16List bl_count) {
    Uint16List next_code = new Uint16List(MAX_BITS + 1);
    int code = 0; // running code value
    int bits; // bit index
    int n; // code index

    // The distribution counts are first used to generate the code values
    // without bit reversal.
    for (bits = 1; bits <= MAX_BITS; bits++) {
      next_code[bits] = code = ((code + bl_count[bits - 1]) << 1);
    }

    for (n = 0; n <= max_code; n++) {
      int len = tree[n * 2 + 1];
      if (len == 0) {
        continue;
      }

      // Now reverse the bits
      tree[n * 2] = (_reverseBits(next_code[len]++, len));
    }
  }

  /**
   * Reverse the first len bits of a code, using straightforward code (a faster
   * method would use a table)
   * IN assertion: 1 <= len <= 15
   */
  static int _reverseBits(int code, int len) {
    int res = 0;
    do {
      res |= code & 1;
      code = _rshift(code, 1);
      res <<= 1;
    } while (--len > 0);
    return _rshift(res, 1);
  }

  /**
   * Mapping from a distance to a distance code. dist is the distance - 1 and
   * must not have side effects. _dist_code[256] and _dist_code[257] are never
   * used.
   */
  static int _dCode(int dist) {
    return ((dist) < 256 ? _DIST_CODE[dist] :
           _DIST_CODE[256 + (_rshift((dist), 7))]);
  }
}

class _StaticTree {
  static const int MAX_BITS = 15;

  static const int BL_CODES = 19;
  static const int D_CODES = 30;
  static const int LITERALS = 256;
  static const int LENGTH_CODES = 29;
  static const int L_CODES = (LITERALS + 1 + LENGTH_CODES);

  // Bit length codes must not exceed MAX_BL_BITS bits
  static const int MAX_BL_BITS = 7;

  static const List<int> STATIC_LTREE = const [
      12, 8, 140, 8, 76, 8, 204, 8, 44, 8, 172, 8, 108, 8, 236, 8, 28, 8, 156,
      8, 92, 8, 220, 8, 60, 8, 188, 8, 124, 8, 252, 8, 2, 8, 130, 8, 66, 8, 194,
      8, 34, 8, 162, 8, 98, 8, 226, 8, 18, 8, 146, 8, 82, 8, 210, 8, 50, 8, 178,
      8, 114, 8, 242, 8, 10, 8, 138, 8, 74, 8, 202, 8, 42, 8, 170, 8, 106, 8,
      234, 8, 26, 8, 154, 8, 90, 8, 218, 8, 58, 8, 186, 8, 122, 8, 250, 8, 6, 8,
      134, 8, 70, 8, 198, 8, 38, 8, 166, 8, 102, 8, 230, 8, 22, 8, 150, 8, 86,
      8, 214, 8, 54, 8, 182, 8, 118, 8, 246, 8, 14, 8, 142, 8, 78, 8, 206, 8,
      46, 8, 174, 8, 110, 8, 238, 8, 30, 8, 158, 8, 94, 8, 222, 8, 62, 8, 190,
      8, 126, 8, 254, 8, 1, 8, 129, 8, 65, 8, 193, 8, 33, 8, 161, 8, 97, 8,
      225, 8, 17, 8, 145, 8, 81, 8, 209, 8, 49, 8, 177, 8, 113, 8, 241, 8, 9,
      8, 137, 8, 73, 8, 201, 8, 41, 8, 169, 8, 105, 8, 233, 8, 25, 8, 153, 8,
      89, 8, 217, 8, 57, 8, 185, 8, 121, 8, 249, 8, 5, 8, 133, 8, 69, 8, 197,
      8, 37, 8, 165, 8, 101, 8, 229, 8, 21, 8, 149, 8, 85, 8, 213, 8, 53, 8,
      181, 8, 117, 8, 245, 8, 13, 8, 141, 8, 77, 8, 205, 8, 45, 8, 173, 8, 109,
      8, 237, 8, 29, 8, 157, 8, 93, 8, 221, 8, 61, 8, 189, 8, 125, 8, 253, 8,
      19, 9, 275, 9, 147, 9, 403, 9, 83, 9, 339, 9, 211, 9, 467, 9, 51, 9, 307,
      9, 179, 9, 435, 9, 115, 9, 371, 9, 243, 9, 499, 9, 11, 9, 267, 9, 139, 9,
      395, 9, 75, 9, 331, 9, 203, 9, 459, 9, 43, 9, 299, 9, 171, 9, 427, 9, 107,
      9, 363, 9, 235, 9, 491, 9, 27, 9, 283, 9, 155, 9, 411, 9, 91, 9, 347, 9,
      219, 9, 475, 9, 59, 9, 315, 9, 187, 9, 443, 9, 123, 9, 379, 9, 251, 9,
      507, 9, 7, 9, 263, 9, 135, 9, 391, 9, 71, 9, 327, 9, 199, 9, 455, 9, 39,
      9, 295, 9, 167, 9, 423, 9, 103, 9, 359, 9, 231, 9, 487, 9, 23, 9, 279, 9,
      151, 9, 407, 9, 87, 9, 343, 9, 215, 9, 471, 9, 55, 9, 311, 9, 183, 9, 439,
      9, 119, 9, 375, 9, 247, 9, 503, 9, 15, 9, 271, 9, 143, 9, 399, 9, 79, 9,
      335, 9, 207, 9, 463, 9, 47, 9, 303, 9, 175, 9, 431, 9, 111, 9, 367, 9,
      239, 9, 495, 9, 31, 9, 287, 9, 159, 9, 415, 9, 95, 9, 351, 9, 223, 9, 479,
      9, 63, 9, 319, 9, 191, 9, 447, 9, 127, 9, 383, 9, 255, 9, 511, 9, 0, 7,
      64, 7, 32, 7, 96, 7, 16, 7, 80, 7, 48, 7, 112, 7, 8, 7, 72, 7, 40, 7, 104,
      7, 24, 7, 88, 7, 56, 7, 120, 7, 4, 7, 68, 7, 36, 7, 100, 7, 20, 7, 84, 7,
      52, 7, 116, 7, 3, 8, 131, 8, 67, 8, 195, 8, 35, 8, 163, 8, 99, 8, 227, 8];

  static const List<int> STATIC_DTREE = const [
      0, 5, 16, 5, 8, 5, 24, 5, 4, 5, 20, 5, 12, 5, 28, 5, 2, 5, 18, 5, 10, 5,
      26, 5, 6, 5, 22, 5, 14, 5, 30, 5, 1, 5, 17, 5, 9, 5, 25, 5, 5, 5, 21, 5,
      13, 5, 29, 5, 3, 5, 19, 5, 11, 5, 27, 5, 7, 5, 23, 5];

  static _StaticTree staticLDesc =
      new _StaticTree(STATIC_LTREE, _HuffmanTree.EXTRA_L_BITS, LITERALS + 1,
                      L_CODES, MAX_BITS);

  static _StaticTree staticDDesc =
      new _StaticTree(STATIC_DTREE, _HuffmanTree.EXTRA_D_BITS, 0, D_CODES, MAX_BITS);

  static _StaticTree staticBlDesc =
      new _StaticTree(null, _HuffmanTree.EXTRA_BL_BITS, 0, BL_CODES, MAX_BL_BITS);

  List<int> staticTree; // static tree or null
  List<int> extraBits; // extra bits for each code or null
  int extraBase; // base index for extra_bits
  int numElements; // max number of elements in the tree
  int maxLength; // max bit length for the codes

  _StaticTree(this.staticTree, this.extraBits, this.extraBase,
             this.numElements, this.maxLength);
}

/**
 * Performs an unsigned bitwise right shift with the specified number
 */
int _rshift(int number, int bits) {
  if ( number >= 0) {
    return number >> bits;
  } else {
    int nbits = (~bits + 0x10000) & 0xffff;
    return (number >> bits) + (2 << nbits);
  }
}

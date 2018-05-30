part of archive;

/**
 * Compress data using the BZip2 format.
 * Derived from libbzip2 (http://www.bzip.org).
 */
class BZip2Encoder {
  List<int> encode(List<int> data) {
    input = new InputStream(data, byteOrder: BIG_ENDIAN);
    OutputStream output = new OutputStream(byteOrder: BIG_ENDIAN);

    bw = new Bz2BitWriter(output);

    final int blockSize100k = 9;

    bw.writeBytes(BZip2.BZH_SIGNATURE);
    bw.writeByte(BZip2.HDR_0 + blockSize100k);

    _nblockMax = 100000 * blockSize100k - 19;
    _workFactor = 30;
    int combinedCRC = 0;

    int n = 100000 * blockSize100k;
    _arr1 = new Uint32List(n);
    _arr2 = new Uint32List(n + BZ_N_OVERSHOOT);
    _ftab = new Uint32List(65537);
    _block = new Uint8List.view(_arr2.buffer);
    _mtfv = new Uint16List.view(_arr1.buffer);
    _unseqToSeq = new Uint8List(256);
    _blockNo = 0;
    _origPtr = 0;

    _selector = new Uint8List(BZ_MAX_SELECTORS);
    _selectorMtf = new Uint8List(BZ_MAX_SELECTORS);
    _len = new List<Uint8List>(BZ_N_GROUPS);
    _code = new List<Int32List>(BZ_N_GROUPS);
    _rfreq = new List<Int32List>(BZ_N_GROUPS);

    for (int i = 0; i < BZ_N_GROUPS; ++i) {
      _len[i] = new Uint8List(BZ_MAX_ALPHA_SIZE);
      _code[i] = new Int32List(BZ_MAX_ALPHA_SIZE);
      _rfreq[i] = new Int32List(BZ_MAX_ALPHA_SIZE);
    }

    _lenPack = new List<Uint32List>(BZ_MAX_ALPHA_SIZE);
    for (int i = 0; i < BZ_MAX_ALPHA_SIZE; ++i) {
      _lenPack[i] = new Uint32List(4);
    }

    // Write blocks
    while (!input.isEOS) {
      int blockCRC = _writeBlock();
      combinedCRC = ((combinedCRC << 1) | (combinedCRC >> 31)) & 0xffffffff;
      combinedCRC ^= blockCRC;
      _blockNo++;
    }

    bw.writeBytes(BZip2.EOS_MAGIC);
    bw.writeUint32(combinedCRC);
    bw.flush();

    return output.getBytes();
  }

  int _writeBlock() {
    _inUse = new Uint8List(256);

    _nblock = 0;
    _blockCRC = BZip2.INITIAL_CRC;

    // copy_input_until_stop
    _state_in_ch = 256;
    _state_in_len = 0;
    while (_nblock < _nblockMax && !input.isEOS) {
      _addCharToBlock(input.readByte());
    }

    if (_state_in_ch < 256) {
      _addPairToBlock();
    }

    _state_in_ch = 256;
    _state_in_len = 0;

    _blockCRC = BZip2.finalizeCrc(_blockCRC);

    _compressBlock();

    return _blockCRC;
  }

  void _compressBlock() {
    if (_nblock > 0) {
      _blockSort();
    }

    if (_nblock > 0) {
      bw.writeBytes(BZip2.COMPRESSED_MAGIC);
      bw.writeUint32(_blockCRC);

      bw.writeBits(1, 0); // set randomize to 'no'

      bw.writeBits(24, _origPtr);

      _generateMTFValues();

      _sendMTFValues();
    }
  }

  void _generateMTFValues() {
    Uint8List yy = new Uint8List(256);

    // After sorting (eg, here),
    // s->arr1 [ 0 .. s->nblock-1 ] holds sorted order,
    // and
    //         ((UChar*)s->arr2) [ 0 .. s->nblock-1 ]
    //         holds the original block data.
    //
    //      The first thing to do is generate the MTF values,
    //      and put them in
    //         ((UInt16*)s->arr1) [ 0 .. s->nblock-1 ].
    //      Because there are strictly fewer or equal MTF values
    //      than block values, ptr values in this area are overwritten
    //      with MTF values only when they are no longer needed.
    //
    //      The final compressed bitstream is generated into the
    //      area starting at
    //         (UChar*) (&((UChar*)s->arr2)[s->nblock])
    _nInUse = 0;
    for (int i = 0; i < 256; i++) {
      if (_inUse[i] != 0) {
        _unseqToSeq[i] = _nInUse;
        _nInUse++;
      }
    }

    final int EOB = _nInUse + 1;

    _mtfFreq = new Int32List(BZ_MAX_ALPHA_SIZE);

    int wr = 0;
    int zPend = 0;
    for (int i = 0; i < _nInUse; i++) {
      yy[i] = i;
    }

    for (int i = 0; i < _nblock; i++) {
      _assert(wr <= i);
      int j = _arr1[i] - 1;
      if (j < 0) {
        j += _nblock;
      }

      int ll_i = _unseqToSeq[_block[j]];
      _assert(ll_i < _nInUse);

      if (yy[0] == ll_i) {
        zPend++;
      } else {
        if (zPend > 0) {
          zPend--;
          while (true) {
            if (zPend & 1 != 0) {
              _mtfv[wr] = BZ_RUNB;
              wr++;
              _mtfFreq[BZ_RUNB]++;
            } else {
              _mtfv[wr] = BZ_RUNA;
              wr++;
              _mtfFreq[BZ_RUNA]++;
            }

            if (zPend < 2) {
              break;
            }

            zPend = (zPend - 2) ~/ 2;
          }

          zPend = 0;
        }

        int rtmp  = yy[1];
        yy[1] = yy[0];
        int ryy_j = 1;
        int rll_i = ll_i;
        while ( rll_i != rtmp ) {
          ryy_j++;
          int rtmp2  = rtmp;
          rtmp = yy[ryy_j];
          yy[ryy_j] = rtmp2;
        }

        yy[0] = rtmp;
        j = ryy_j;

        _mtfv[wr] = j + 1;
        wr++;
        _mtfFreq[j + 1]++;
      }
    }

    if (zPend > 0) {
      zPend--;
      while (true) {
        if (zPend & 1 != 0) {
          _mtfv[wr] = BZ_RUNB;
          wr++;
          _mtfFreq[BZ_RUNB]++;
        } else {
          _mtfv[wr] = BZ_RUNA;
          wr++;
          _mtfFreq[BZ_RUNA]++;
        }
        if (zPend < 2) {
          break;
        }

        zPend = (zPend - 2) ~/ 2;
      }

      zPend = 0;
    }

    _mtfv[wr] = EOB;
    wr++;
    _mtfFreq[EOB]++;

    _nMTF = wr;
  }

  void _sendMTFValues() {
    Uint16List cost = new Uint16List(BZ_N_GROUPS);
    Int32List fave = new Int32List(BZ_N_GROUPS);
    int nSelectors = 0;

    int alphaSize = _nInUse + 2;
    for (int t = 0; t < BZ_N_GROUPS; t++) {
      for (int v = 0; v < alphaSize; v++) {
        _len[t][v] = BZ_GREATER_ICOST;
      }
    }

    // Decide how many coding tables to use
    int nGroups;
    _assert(_nMTF > 0);
    if (_nMTF < 200) {
      nGroups = 2;
    } else if (_nMTF < 600) {
      nGroups = 3;
    } else if (_nMTF < 1200) {
      nGroups = 4;
    } else if (_nMTF < 2400) {
      nGroups = 5;
    } else {
      nGroups = 6;
    }

    // Generate an initial set of coding tables
    int nPart = nGroups;
    int remF = _nMTF;
    int gs = 0;
    int ge = 0;

    while (nPart > 0) {
      int tFreq = remF ~/ nPart;
      int aFreq = 0;
      ge = gs - 1;

      while (aFreq < tFreq && ge < alphaSize-1) {
        ge++;
        aFreq += _mtfFreq[ge];
      }

      if (ge > gs && nPart != nGroups && nPart != 1 &&
          ((nGroups - nPart) % 2 == 1)) {
        aFreq -= _mtfFreq[ge];
        ge--;
      }

      for (int v = 0; v < alphaSize; v++) {
        if (v >= gs && v <= ge) {
          _len[nPart - 1][v] = BZ_LESSER_ICOST;
        } else {
          _len[nPart - 1][v] = BZ_GREATER_ICOST;
        }
      }

      nPart--;
      gs = ge + 1;
      remF -= aFreq;
    }

    // Iterate up to BZ_N_ITERS times to improve the tables.
    for (int iter = 0; iter < BZ_N_ITERS; iter++) {
      for (int t = 0; t < nGroups; t++) {
        fave[t] = 0;
      }
      for (int t = 0; t < nGroups; t++) {
        for (int v = 0; v < alphaSize; v++) {
          _rfreq[t][v] = 0;
        }
      }

      // Set up an auxiliary length table which is used to fast-track
      // the common case (nGroups == 6).
      if (nGroups == 6) {
        for (int v = 0; v < alphaSize; v++) {
          _lenPack[v][0] = (_len[1][v] << 16) | _len[0][v];
          _lenPack[v][1] = (_len[3][v] << 16) | _len[2][v];
          _lenPack[v][2] = (_len[5][v] << 16) | _len[4][v];
        }
      }

      nSelectors = 0;
      int totc = 0; // ignore: unused_local_variable
      gs = 0;
      while (true) {
        // Set group start & end marks.
        if (gs >= _nMTF) {
          break;
        }

        int ge = gs + BZ_G_SIZE - 1;
        if (ge >= _nMTF) {
          ge = _nMTF - 1;
        }

        // Calculate the cost of this group as coded
        // by each of the coding tables.
        for (int t = 0; t < nGroups; t++) {
          cost[t] = 0;
        }

        if (nGroups == 6 && 50 == ge - gs + 1) {
          // fast track the common case
          int cost01 = 0;
          int cost23 = 0;
          int cost45 = 0;

          void BZ_ITER(int nn) {
            int icv = _mtfv[gs + nn];
            cost01 += _lenPack[icv][0];
            cost23 += _lenPack[icv][1];
            cost45 += _lenPack[icv][2];
          }

          BZ_ITER(0);  BZ_ITER(1);  BZ_ITER(2);  BZ_ITER(3);  BZ_ITER(4);
          BZ_ITER(5);  BZ_ITER(6);  BZ_ITER(7);  BZ_ITER(8);  BZ_ITER(9);
          BZ_ITER(10); BZ_ITER(11); BZ_ITER(12); BZ_ITER(13); BZ_ITER(14);
          BZ_ITER(15); BZ_ITER(16); BZ_ITER(17); BZ_ITER(18); BZ_ITER(19);
          BZ_ITER(20); BZ_ITER(21); BZ_ITER(22); BZ_ITER(23); BZ_ITER(24);
          BZ_ITER(25); BZ_ITER(26); BZ_ITER(27); BZ_ITER(28); BZ_ITER(29);
          BZ_ITER(30); BZ_ITER(31); BZ_ITER(32); BZ_ITER(33); BZ_ITER(34);
          BZ_ITER(35); BZ_ITER(36); BZ_ITER(37); BZ_ITER(38); BZ_ITER(39);
          BZ_ITER(40); BZ_ITER(41); BZ_ITER(42); BZ_ITER(43); BZ_ITER(44);
          BZ_ITER(45); BZ_ITER(46); BZ_ITER(47); BZ_ITER(48); BZ_ITER(49);

          cost[0] = cost01 & 0xffff;
          cost[1] = cost01 >> 16;
          cost[2] = cost23 & 0xffff;
          cost[3] = cost23 >> 16;
          cost[4] = cost45 & 0xffff;
          cost[5] = cost45 >> 16;
        } else {
          // slow version which correctly handles all situations
          for (int i = gs; i <= ge; i++) {
            int icv = _mtfv[i];
            for (int t = 0; t < nGroups; t++) {
              cost[t] += _len[t][icv];
            }
          }
        }

        // Find the coding table which is best for this group,
        // and record its identity in the selector table.
        int bc = 999999999;
        int bt = -1;
        for (int t = 0; t < nGroups; t++) {
          if (cost[t] < bc) {
            bc = cost[t];
            bt = t;
          }
        }

        totc += bc;
        fave[bt]++;
        _selector[nSelectors] = bt;
        nSelectors++;

        // Increment the symbol frequencies for the selected table.
        if (nGroups == 6 && 50 == ge - gs + 1) {
          // fast track the common case
          void BZ_ITUR(int nn) {
            _rfreq[bt][_mtfv[gs + nn]]++;
          }

          BZ_ITUR(0);  BZ_ITUR(1);  BZ_ITUR(2);  BZ_ITUR(3);  BZ_ITUR(4);
          BZ_ITUR(5);  BZ_ITUR(6);  BZ_ITUR(7);  BZ_ITUR(8);  BZ_ITUR(9);
          BZ_ITUR(10); BZ_ITUR(11); BZ_ITUR(12); BZ_ITUR(13); BZ_ITUR(14);
          BZ_ITUR(15); BZ_ITUR(16); BZ_ITUR(17); BZ_ITUR(18); BZ_ITUR(19);
          BZ_ITUR(20); BZ_ITUR(21); BZ_ITUR(22); BZ_ITUR(23); BZ_ITUR(24);
          BZ_ITUR(25); BZ_ITUR(26); BZ_ITUR(27); BZ_ITUR(28); BZ_ITUR(29);
          BZ_ITUR(30); BZ_ITUR(31); BZ_ITUR(32); BZ_ITUR(33); BZ_ITUR(34);
          BZ_ITUR(35); BZ_ITUR(36); BZ_ITUR(37); BZ_ITUR(38); BZ_ITUR(39);
          BZ_ITUR(40); BZ_ITUR(41); BZ_ITUR(42); BZ_ITUR(43); BZ_ITUR(44);
          BZ_ITUR(45); BZ_ITUR(46); BZ_ITUR(47); BZ_ITUR(48); BZ_ITUR(49);
        } else {
          // slow version which correctly handles all situations
          for (int i = gs; i <= ge; i++) {
            _rfreq[bt][_mtfv[i]]++;
          }
        }

        gs = ge + 1;
      }

      // Recompute the tables based on the accumulated frequencies.
      for (int t = 0; t < nGroups; t++) {
        _hbMakeCodeLengths(_len[t], _rfreq[t], alphaSize, 17);
      }
    }

    _assert(nGroups < 8);
    _assert(nSelectors < 32768 && nSelectors <= (2 + (900000 ~/ BZ_G_SIZE)));

    // Compute MTF values for the selectors.
    Uint8List pos = new Uint8List(BZ_N_GROUPS);
    for (int i = 0; i < nGroups; i++) {
      pos[i] = i;
    }

    for (int i = 0; i < nSelectors; i++) {
      int ll_i = _selector[i];
      int j = 0;
      int tmp = pos[j];
      while (ll_i != tmp) {
        j++;
        int tmp2 = tmp;
        tmp = pos[j];
        pos[j] = tmp2;
      }
      pos[0] = tmp;
      _selectorMtf[i] = j;
    }

    // Assign actual codes for the tables.
    for (int t = 0; t < nGroups; t++) {
      int minLen = 32;
      int maxLen = 0;
      for (int i = 0; i < alphaSize; i++) {
        if (_len[t][i] > maxLen) {
          maxLen = _len[t][i];
        }
        if (_len[t][i] < minLen) {
          minLen = _len[t][i];
        }
      }
      _assert(!(maxLen > 17));
      _assert(!(minLen < 1));
      _hbAssignCodes(_code[t], _len[t], minLen, maxLen, alphaSize );
    }

    // Transmit the mapping table.
    Uint8List inUse16 = new Uint8List(16);
    for (int i = 0; i < 16; i++) {
      inUse16[i] = 0;
      for (int j = 0; j < 16; j++) {
        if (_inUse[i * 16 + j] != 0) {
          inUse16[i] = 1;
        }
      }
    }

    for (int i = 0; i < 16; i++) {
      if (inUse16[i] != 0) {
        bw.writeBits(1, 1);
      } else {
        bw.writeBits(1, 0);
      }
    }

    for (int i = 0; i < 16; i++) {
      if (inUse16[i] != 0) {
        for (int j = 0; j < 16; j++) {
          if (_inUse[i * 16 + j] != 0) {
            bw.writeBits(1, 1);
          } else {
            bw.writeBits(1, 0);
          }
        }
      }
    }

    // Now the selectors.
    bw.writeBits(3, nGroups);
    bw.writeBits(15, nSelectors);
    for (int i = 0; i < nSelectors; i++) {
      for (int j = 0; j < _selectorMtf[i]; j++) {
        bw.writeBits(1, 1);
      }
      bw.writeBits(1, 0);
    }

    // Now the coding tables.
    for (int t = 0; t < nGroups; t++) {
      int curr = _len[t][0];
      bw.writeBits(5, curr);
      for (int i = 0; i < alphaSize; i++) {
        while (curr < _len[t][i]) {
          bw.writeBits(2, 2);
          curr++; // 10
        }

        while (curr > _len[t][i]) {
          bw.writeBits(2, 3);
          curr--; // 11
        }

        bw.writeBits(1, 0);
      }
    }

    // And finally, the block data proper
    int selCtr = 0;
    gs = 0;
    while (true) {
      if (gs >= _nMTF) {
        break;
      }

      int ge = gs + BZ_G_SIZE - 1;
      if (ge >= _nMTF) {
        ge = _nMTF - 1;
      }

      _assert(_selector[selCtr] < nGroups);

      if (nGroups == 6 && 50 == ge - gs + 1) {
        // fast track the common case
        int mtfv_i;
        Uint8List s_len_sel_selCtr = _len[_selector[selCtr]];
        Int32List s_code_sel_selCtr = _code[_selector[selCtr]];

        void BZ_ITAH(int nn) {
          mtfv_i = _mtfv[gs + nn];
          bw.writeBits(s_len_sel_selCtr[mtfv_i], s_code_sel_selCtr[mtfv_i]);
        }

        BZ_ITAH(0);  BZ_ITAH(1);  BZ_ITAH(2);  BZ_ITAH(3);  BZ_ITAH(4);
        BZ_ITAH(5);  BZ_ITAH(6);  BZ_ITAH(7);  BZ_ITAH(8);  BZ_ITAH(9);
        BZ_ITAH(10); BZ_ITAH(11); BZ_ITAH(12); BZ_ITAH(13); BZ_ITAH(14);
        BZ_ITAH(15); BZ_ITAH(16); BZ_ITAH(17); BZ_ITAH(18); BZ_ITAH(19);
        BZ_ITAH(20); BZ_ITAH(21); BZ_ITAH(22); BZ_ITAH(23); BZ_ITAH(24);
        BZ_ITAH(25); BZ_ITAH(26); BZ_ITAH(27); BZ_ITAH(28); BZ_ITAH(29);
        BZ_ITAH(30); BZ_ITAH(31); BZ_ITAH(32); BZ_ITAH(33); BZ_ITAH(34);
        BZ_ITAH(35); BZ_ITAH(36); BZ_ITAH(37); BZ_ITAH(38); BZ_ITAH(39);
        BZ_ITAH(40); BZ_ITAH(41); BZ_ITAH(42); BZ_ITAH(43); BZ_ITAH(44);
        BZ_ITAH(45); BZ_ITAH(46); BZ_ITAH(47); BZ_ITAH(48); BZ_ITAH(49);
      } else {
        // slow version which correctly handles all situations
        for (int i = gs; i <= ge; i++) {
          bw.writeBits(_len[_selector[selCtr]][_mtfv[i]],
                       _code[_selector[selCtr]][_mtfv[i]]);
        }
      }

      gs = ge + 1;
      selCtr++;
    }

    _assert(selCtr == nSelectors);
  }

  void _hbMakeCodeLengths(Uint8List len, Int32List freq,
                          int alphaSize, int maxLen) {
    // Nodes and heap entries run from 1.  Entry 0
    // for both the heap and nodes is a sentinel.
    Int32List heap = new Int32List(BZ_MAX_ALPHA_SIZE + 2);
    Int32List weight = new Int32List(BZ_MAX_ALPHA_SIZE * 2);
    Int32List parent = new Int32List(BZ_MAX_ALPHA_SIZE * 2);
    int nHeap;
    int nNodes;

    for (int i = 0; i < alphaSize; i++) {
      weight[i+1] = (freq[i] == 0 ? 1 : freq[i]) << 8;
    }

    void UPHEAP(int z) {
      int zz = z;
      int tmp = heap[zz];
      while (weight[tmp] < weight[heap[zz >> 1]]) {
        heap[zz] = heap[zz >> 1];
        zz >>= 1;
      }
      heap[zz] = tmp;
    }

    void DOWNHEAP(int z) {
      int zz = z;
      int tmp = heap[zz];
      while (true) {
        int yy = zz << 1;
        if (yy > nHeap) {
          break;
        }
        if (yy < nHeap && weight[heap[yy+1]] < weight[heap[yy]]) {
          yy++;
        }
        if (weight[tmp] < weight[heap[yy]]) {
          break;
        }
        heap[zz] = heap[yy];
        zz = yy;
      }
      heap[zz] = tmp;
    }

    int WEIGHTOF(int zz0) => ((zz0) & 0xffffff00);
    int DEPTHOF(int zz1) => ((zz1) & 0x000000ff);
    int MYMAX(int zz2, int zz3) => ((zz2) > (zz3) ? (zz2) : (zz3));
    int ADDWEIGHTS(int zw1, int zw2) =>
      (WEIGHTOF(zw1) + WEIGHTOF(zw2)) |
      (1 + MYMAX(DEPTHOF(zw1), DEPTHOF(zw2)));

    while (true) {
      nNodes = alphaSize;
      nHeap = 0;

      heap[0] = 0;
      weight[0] = 0;
      parent[0] = -2;

      for (int i = 1; i <= alphaSize; i++) {
       parent[i] = -1;
       nHeap++;
       heap[nHeap] = i;
       UPHEAP(nHeap);
      }

      _assert(nHeap < (BZ_MAX_ALPHA_SIZE + 2));

      while (nHeap > 1) {
        int n1 = heap[1];
        heap[1] = heap[nHeap];
        nHeap--;
        DOWNHEAP(1);
        int n2 = heap[1];
        heap[1] = heap[nHeap];
        nHeap--;
        DOWNHEAP(1);
        nNodes++;
        parent[n1] = parent[n2] = nNodes;
        weight[nNodes] = ADDWEIGHTS(weight[n1], weight[n2]);
        parent[nNodes] = -1;
        nHeap++;
        heap[nHeap] = nNodes;
        UPHEAP(nHeap);
      }

      _assert(nNodes < (BZ_MAX_ALPHA_SIZE * 2));

      bool tooLong = false;
      for (int i = 1; i <= alphaSize; i++) {
        int j = 0;
        int k = i;
        while (parent[k] >= 0) {
          k = parent[k];
          j++;
        }
        len[i - 1] = j;
        if (j > maxLen) {
          tooLong = true;
        }
      }

      if (!tooLong) {
        break;
      }

      for (int i = 1; i <= alphaSize; i++) {
        int j = weight[i] >> 8;
        j = 1 + (j ~/ 2);
        weight[i] = j << 8;
      }
    }
  }

  void _hbAssignCodes(Int32List codes, Uint8List length,
                      int minLen, int maxLen, int alphaSize) {
    int vec = 0;
    for (int n = minLen; n <= maxLen; n++) {
      for (int i = 0; i < alphaSize; i++) {
        if (length[i] == n) {
          codes[i] = vec;
          vec++;
        }
      }
      vec <<= 1;
    }
  }

  void _blockSort() {
    if (_nblock < 10000) {
      _fallbackSort(_arr1, _arr2, _ftab, _nblock);
    } else {
      // Calculate the location for quadrant, remembering to get
      // the alignment right.  Assumes that &(block[0]) is at least
      // 2-byte aligned -- this should be ok since block is really
      // the first section of arr2.
      int i = _nblock + BZ_N_OVERSHOOT;
      if (i & 1 != 0) {
        i++;
      }
      Uint16List quadrant = new Uint16List.view(_block.buffer, i);

      int wfact = _workFactor;
      // (wfact-1) / 3 puts the default-factor-30
      // transition point at very roughly the same place as
      // with v0.1 and v0.9.0.
      // Not that it particularly matters any more, since the
      // resulting compressed stream is now the same regardless
      // of whether or not we use the main sort or fallback sort.
      if (wfact < 1) {
        wfact = 1;
      }
      if (wfact > 100) {
        wfact = 100;
      }

      int budgetInit = _nblock * ((wfact - 1) ~/ 3);
      _budget = budgetInit;

      _mainSort(_arr1, _block, quadrant, _ftab, _nblock);
      if (_budget < 0) {
        _fallbackSort(_arr1, _arr2, _ftab, _nblock);
      }
    }

    _origPtr = -1;
    for (int i = 0; i < _nblock; i++) {
      if (_arr1[i] == 0) {
        _origPtr = i;
        break;
      }
    }

    _assert(_origPtr != -1);
  }

  void _assert(bool cond) {
    if (!cond) {
      throw new ArchiveException('Data error');
    }
  }

  void _fallbackSort(Uint32List fmap, Uint32List eclass,
                     Uint32List bhtab, int nblock) {
    Int32List ftab = new Int32List(257);
    Int32List ftabCopy = new Int32List(256);
    Uint8List eclass8 = new Uint8List.view(eclass.buffer);

    int SET_BH(int zz) => bhtab[zz >> 5] |= (1 << (zz & 31));
    int CLEAR_BH(int zz) => bhtab[zz >> 5] &= ~(1 << (zz & 31));
    bool ISSET_BH(int zz) => (bhtab[zz >> 5] & (1 << (zz & 31)) != 0);
    int WORD_BH(int zz) => bhtab[(zz) >> 5];
    bool UNALIGNED_BH(int zz) => ((zz) & 0x01f) != 0;

    // Initial 1-char radix sort to generate
    // initial fmap and initial BH bits.
    for (int i = 0; i < 257; i++) {
      ftab[i] = 0;
    }
    for (int i = 0; i < nblock; i++) {
      ftab[eclass8[i]]++;
    }
    for (int i = 0; i < 256; i++) {
      ftabCopy[i] = ftab[i];
    }
    for (int i = 1; i < 257; i++) {
      ftab[i] += ftab[i - 1];
    }

    for (int i = 0; i < nblock; i++) {
      int j = eclass8[i];
      int k = ftab[j] - 1;
      ftab[j] = k;
      fmap[k] = i;
    }

    int nBhtab = 2 + (nblock ~/ 32);
    for (int i = 0; i < nBhtab; i++) {
      bhtab[i] = 0;
    }

    for (int i = 0; i < 256; i++) {
      SET_BH(ftab[i]);
    }

    // Inductively refine the buckets.  Kind-of an
    // "exponential radix sort" (!), inspired by the
    // Manber-Myers suffix array construction algorithm.

    // set sentinel bits for block-end detection
    for (int i = 0; i < 32; i++) {
      SET_BH(nblock + 2*i);
      CLEAR_BH(nblock + 2*i + 1);
    }

    // the log(N) loop
    int H = 1;
    while (true) {
      int j = 0;
      for (int i = 0; i < nblock; i++) {
        if (ISSET_BH(i)) {
          j = i;
        }
        int k = fmap[i] - H;
        if (k < 0) {
          k += nblock;
        }
        eclass[k] = j;
      }

      int nNotDone = 0;
      int r = -1;
      while (true) {
        // find the next non-singleton bucket
        int k = r + 1;
        while (ISSET_BH(k) && UNALIGNED_BH(k)) {
          k++;
        }
        if (ISSET_BH(k)) {
          while (WORD_BH(k) == 0xffffffff) {
            k += 32;
          }
          while (ISSET_BH(k)) {
            k++;
          }
        }

        int l = k - 1;
        if (l >= nblock) {
          break;
        }
        while (!ISSET_BH(k) && UNALIGNED_BH(k)) {
          k++;
        }
        if (!ISSET_BH(k)) {
          while (WORD_BH(k) == 0x00000000) {
            k += 32;
          }
          while (!ISSET_BH(k)) {
            k++;
          }
        }

        r = k - 1;
        if (r >= nblock) {
          break;
        }

        // now [l, r] bracket current bucket
        if (r > l) {
          nNotDone += (r - l + 1);
          _fallbackQSort3(fmap, eclass, l, r);

          // scan bucket and generate header bits
          int cc = -1;
          for (int i = l; i <= r; i++) {
            int cc1 = eclass[fmap[i]];
            if (cc != cc1) {
              SET_BH(i);
              cc = cc1;
            }
          }
        }
      }

      H *= 2;
      if (H > nblock || nNotDone == 0) {
        break;
      }
    }

    // Reconstruct the original block in
    // eclass8 [0 .. nblock-1], since the
    // previous phase destroyed it.
    int j = 0;
    for (int i = 0; i < nblock; i++) {
      while (ftabCopy[j] == 0) {
        j++;
      }
      ftabCopy[j]--;
      eclass8[fmap[i]] = j;
    }
    _assert(j < 256);
  }

  void _fallbackQSort3(Uint32List fmap, Uint32List eclass,
                      int loSt, int hiSt) {
    const int FALLBACK_QSORT_SMALL_THRESH = 10;
    const int FALLBACK_QSORT_STACK_SIZE = 100;

    Int32List stackLo = new Int32List(FALLBACK_QSORT_STACK_SIZE);
    Int32List stackHi = new Int32List(FALLBACK_QSORT_STACK_SIZE);
    int sp = 0;

    void fpush(int lz, int hz) {
      stackLo[sp] = lz;
      stackHi[sp] = hz;
      sp++;
    }

    int fmin(int a, int b) => ((a) < (b)) ? (a) : (b);

    void fvswap(yyp1, yyp2, yyn) {
      while (yyn > 0) {
        int t = fmap[yyp1];
        fmap[yyp1] = fmap[yyp2];
        fmap[yyp2] = t;
        yyp1++;
        yyp2++;
        yyn--;
       }
    }


    int r = 0;

    fpush(loSt, hiSt);

    while (sp > 0) {
      _assert(sp < FALLBACK_QSORT_STACK_SIZE - 1);

      sp--;
      int lo = stackLo[sp];
      int hi = stackHi[sp];

      if (hi - lo < FALLBACK_QSORT_SMALL_THRESH) {
        _fallbackSimpleSort(fmap, eclass, lo, hi);
        continue;
      }

      // Random partitioning.  Median of 3 sometimes fails to
      // avoid bad cases.  Median of 9 seems to help but
      // looks rather expensive.  This too seems to work but
      // is cheaper.  Guidance for the magic constants
      // 7621 and 32768 is taken from Sedgewick's algorithms
      // book, chapter 35.
      r = ((r * 7621) + 1) % 32768;
      int r3 = r % 3;
      int med;
      if (r3 == 0) {
        med = eclass[fmap[lo]];
      } else if (r3 == 1) {
        med = eclass[fmap[(lo+hi)>>1]];
      } else {
        med = eclass[fmap[hi]];
      }

      int unLo = lo;
      int ltLo = lo;
      int unHi = hi;
      int gtHi = hi;

      while (true) {
        while (true) {
          if (unLo > unHi) {
            break;
          }

          int n = eclass[fmap[unLo]] - med;
          if (n == 0) {
            int t = fmap[unLo];
            fmap[unLo] = fmap[ltLo];
            fmap[ltLo] = t;
            ltLo++;
            unLo++;
            continue;
          }
          if (n > 0) {
            break;
          }
          unLo++;
        }
        while (true) {
          if (unLo > unHi) {
            break;
          }
          int n = eclass[fmap[unHi]] - med;
          if (n == 0) {
            int t = fmap[unHi];
            fmap[unHi] = fmap[gtHi];
            fmap[gtHi] = t;
            gtHi--;
            unHi--;
            continue;
          }
          if (n < 0) {
            break;
          }
          unHi--;
        }
        if (unLo > unHi) {
          break;
        }

        int t = fmap[unLo];
        fmap[unLo] = fmap[unHi];
        fmap[unHi] = t;
        unLo++;
        unHi--;
      }

      _assert(unHi == unLo - 1);

      if (gtHi < ltLo) {
        continue;
      }

      int n = fmin(ltLo - lo, unLo - ltLo);
      fvswap(lo, unLo - n, n);
      int m = fmin(hi - gtHi, gtHi - unHi);
      fvswap(unLo, hi - m + 1, m);

      n = lo + unLo - ltLo - 1;
      m = hi - (gtHi - unHi) + 1;

      if (n - lo > hi - m) {
        fpush(lo, n);
        fpush(m, hi);
      } else {
        fpush(m, hi);
        fpush(lo, n);
      }
    }
  }

  void _fallbackSimpleSort(Uint32List fmap, Uint32List eclass,
                           int lo, int hi) {
    if (lo == hi) {
      return;
    }

    if (hi - lo > 3) {
      for (int i = hi - 4; i >= lo; i--) {
        int tmp = fmap[i];
        int ec_tmp = eclass[tmp];
        int j;
        for (j = i + 4; j <= hi && ec_tmp > eclass[fmap[j]]; j += 4) {
          fmap[j - 4] = fmap[j];
        }
        fmap[j - 4] = tmp;
      }
    }

    for (int i = hi - 1; i >= lo; i--) {
      int tmp = fmap[i];
      int ec_tmp = eclass[tmp];
      int j;
      for (j = i + 1; j <= hi && ec_tmp > eclass[fmap[j]]; j++) {
        fmap[j - 1] = fmap[j];
      }
      fmap[j - 1] = tmp;
    }
  }

  void _mainSort(Uint32List ptr, Uint8List block,
                 Uint16List quadrant, Uint32List ftab,
                 int nblock) {
    Int32List runningOrder = new Int32List(256);
    Uint8List bigDone = new Uint8List(256);
    Int32List copyStart = new Int32List(256);
    Int32List copyEnd = new Int32List(256);

    int BIGFREQ(int b) =>
        (_ftab[((b) + 1) << 8] - _ftab[(b) << 8]);

    const int SETMASK = 2097152;
    const int CLEARMASK = 4292870143;

    // set up the 2-byte frequency table
    for (int i = 65536; i >= 0; i--) {
      ftab[i] = 0;
    }

    int j = block[0] << 8;
    int i = nblock - 1;

    for (; i >= 3; i -= 4) {
      quadrant[i] = 0;
      j = (j >> 8) | ((block[i]) << 8);
      ftab[j]++;
      quadrant[i - 1] = 0;
      j = (j >> 8) | ((block[i - 1]) << 8);
      ftab[j]++;
      quadrant[i - 2] = 0;
      j = (j >> 8) | ((block[i - 2]) << 8);
      ftab[j]++;
      quadrant[i - 3] = 0;
      j = (j >> 8) | ((block[i - 3]) << 8);
      ftab[j]++;
    }

    for (; i >= 0; i--) {
      quadrant[i] = 0;
      j = (j >> 8) | ((block[i]) << 8);
      ftab[j]++;
    }

    // (emphasises close relationship of block & quadrant)
    for (i = 0; i < BZ_N_OVERSHOOT; i++) {
      block[nblock + i] = block[i];
      quadrant[nblock + i] = 0;
    }

    // Complete the initial radix sort
    for (i = 1; i <= 65536; i++) {
      ftab[i] += ftab[i - 1];
    }

    int s = block[0] << 8;
    i = nblock - 1;
    for (; i >= 3; i -= 4) {
      s = (s >> 8) | (block[i] << 8);
      j = ftab[s] -1;
      ftab[s] = j;
      ptr[j] = i;
      s = (s >> 8) | (block[i - 1] << 8);
      j = ftab[s] -1;
      ftab[s] = j;
      ptr[j] = i-1;
      s = (s >> 8) | (block[i - 2] << 8);
      j = ftab[s] -1;
      ftab[s] = j;
      ptr[j] = i-2;
      s = (s >> 8) | (block[i - 3] << 8);
      j = ftab[s] -1;
      ftab[s] = j;
      ptr[j] = i-3;
    }
    for (; i >= 0; i--) {
      s = (s >> 8) | (block[i] << 8);
      j = ftab[s] -1;
      ftab[s] = j;
      ptr[j] = i;
    }

    // Now ftab contains the first loc of every small bucket.
    // Calculate the running order, from smallest to largest
    // big bucket.
    for (i = 0; i <= 255; i++) {
      bigDone[i] = 0;
      runningOrder[i] = i;
    }

    int h = 1;
    do {
      h = 3 * h + 1;
    } while (h <= 256);
    do {
      h = h ~/ 3;
      for (i = h; i <= 255; i++) {
        int vv = runningOrder[i];
        j = i;
        while (BIGFREQ(runningOrder[j-h]) > BIGFREQ(vv)) {
          runningOrder[j] = runningOrder[j-h];
          j = j - h;
          if (j <= (h - 1)) {
            break;
          }
        }
        runningOrder[j] = vv;
      }
    } while (h != 1);

    // The main sorting loop.

    int numQSorted = 0; // ignore: unused_local_variable

    for (i = 0; i <= 255; i++) {
      // Process big buckets, starting with the least full.
      // Basically this is a 3-step process in which we call
      // mainQSort3 to sort the small buckets [ss, j], but
      // also make a big effort to avoid the calls if we can.
      int ss = runningOrder[i];

      // Step 1:
      // Complete the big bucket [ss] by quicksorting
      // any unsorted small buckets [ss, j], for j != ss.
      // Hopefully previous pointer-scanning phases have already
      // completed many of the small buckets [ss, j], so
      // we don't have to sort them at all.
      for (j = 0; j <= 255; j++) {
        if (j != ss) {
          int sb = (ss << 8) + j;
          if ((_ftab[sb] & SETMASK) == 0) {
            int lo = _ftab[sb] & CLEARMASK;
            int hi = (_ftab[sb + 1] & CLEARMASK) - 1;
            if (hi > lo) {
              _mainQSort3(ptr, block, quadrant, nblock,
                         lo, hi, BZ_N_RADIX);
              numQSorted += (hi - lo + 1);
              if (_budget < 0) {
                return;
              }
            }
          }
          _ftab[sb] |= SETMASK;
        }
      }

      _assert(bigDone[ss] == 0);

      // Step 2:
      // Now scan this big bucket [ss] so as to synthesise the
      // sorted order for small buckets [t, ss] for all t,
      // including, magically, the bucket [ss,ss] too.
      // This will avoid doing Real Work in subsequent Step 1's.
      for (j = 0; j <= 255; j++) {
        copyStart[j] = _ftab[(j << 8) + ss] & CLEARMASK;
        copyEnd[j] = (_ftab[(j << 8) + ss + 1] & CLEARMASK) - 1;
      }

      for (j = _ftab[ss << 8] & CLEARMASK; j < copyStart[ss]; j++) {
        int k = ptr[j]-1; if (k < 0) k += nblock;
        int c1 = block[k];
        if (bigDone[c1] == 0) {
           ptr[ copyStart[c1]++ ] = k;
        }
      }

      for (j = (_ftab[(ss+1) << 8] & CLEARMASK) - 1; j > copyEnd[ss]; j--) {
        int k = ptr[j] - 1;
        if (k < 0) {
          k += nblock;
        }
        int c1 = block[k];
        if (bigDone[c1] == 0) {
          ptr[copyEnd[c1]--] = k;
        }
      }

      _assert((copyStart[ss] - 1 == copyEnd[ss]) ||
              // Extremely rare case missing in bzip2-1.0.0 and 1.0.1.
              // Necessity for this case is demonstrated by compressing
              // a sequence of approximately 48.5 million of character
              // 251; 1.0.0/1.0.1 will then die here.
              (copyStart[ss] == 0 && copyEnd[ss] == nblock - 1));

      for (j = 0; j <= 255; j++) {
        _ftab[(j << 8) + ss] |= SETMASK;
      }

      // Step 3:
      // The [ss] big bucket is now done.  Record this fact,
      // and update the quadrant descriptors.  Remember to
      // update quadrants in the overshoot area too, if
      // necessary.  The "if (i < 255)" test merely skips
      // this updating for the last bucket processed, since
      // updating for the last bucket is pointless.
      //
      // The quadrant array provides a way to incrementally
      // cache sort orderings, as they appear, so as to
      // make subsequent comparisons in fullGtU() complete
      // faster.  For repetitive blocks this makes a big
      // difference (but not big enough to be able to avoid
      // the fallback sorting mechanism, exponential radix sort).
      //
      // The precise meaning is: at all times:
      //
      //          for 0 <= i < nblock and 0 <= j <= nblock
      //
      //          if block[i] != block[j],
      //
      //             then the relative values of quadrant[i] and
      //                  quadrant[j] are meaningless.
      //
      //             else {
      //                if quadrant[i] < quadrant[j]
      //                   then the string starting at i lexicographically
      //                   precedes the string starting at j
      //
      //                else if quadrant[i] > quadrant[j]
      //                   then the string starting at j lexicographically
      //                   precedes the string starting at i
      //
      //                else
      //                   the relative ordering of the strings starting
      //                   at i and j has not yet been determined.
      //             }
      bigDone[ss] = 1;

      if (i < 255) {
        int bbStart = _ftab[ss << 8] & CLEARMASK;
        int bbSize = (_ftab[(ss + 1) << 8] & CLEARMASK) - bbStart;
        int shifts = 0;

        while ((bbSize >> shifts) > 65534) {
          shifts++;
        }

        for (j = bbSize - 1; j >= 0; j--) {
          int a2update = ptr[bbStart + j];
          int qVal = (j >> shifts) & 0xffff;
          quadrant[a2update] = qVal;
          if (a2update < BZ_N_OVERSHOOT)
            quadrant[a2update + nblock] = qVal;
          }
          _assert(((bbSize - 1) >> shifts) <= 65535);
        }
      }
  }

  void _mainQSort3(Uint32List ptr, Uint8List block,
                  Uint16List quadrant, int nblock,
                  int loSt, int hiSt, int dSt) {
    const MAIN_QSORT_STACK_SIZE = 100;
    const MAIN_QSORT_SMALL_THRESH = 20;
    const MAIN_QSORT_DEPTH_THRESH = (BZ_N_RADIX + BZ_N_QSORT);

    Int32List stackLo = new Int32List(MAIN_QSORT_STACK_SIZE);
    Int32List stackHi = new Int32List(MAIN_QSORT_STACK_SIZE);
    Int32List stackD = new Int32List(MAIN_QSORT_STACK_SIZE);

    Int32List nextLo = new Int32List(3);
    Int32List nextHi = new Int32List(3);
    Int32List nextD = new Int32List(3);

    int sp = 0;
    void mpush(int lz, int hz, int dz) {
      stackLo[sp] = lz;
      stackHi[sp] = hz;
      stackD[sp] = dz;
      sp++;
    }

    int mmed3(int a, int b, int c) {
      if (a > b) {
        int t = a;
        a = b;
        b = t;
      }
      if (b > c) {
        b = c;
        if (a > b) {
          b = a;
        }
      }
      return b;
    }

    void mvswap(int yyp1, int yyp2, int yyn) {
      while (yyn > 0) {
        int t = ptr[yyp1];
        ptr[yyp1] = ptr[yyp2];
        ptr[yyp2] = t;
        yyp1++;
        yyp2++;
        yyn--;
      }
    }

    int mmin(int a, int b) => ((a) < (b)) ? (a) : (b);

    int mnextsize(int az) => (nextHi[az] - nextLo[az]);

    void mnextswap(int az, int bz) {
      int tz = nextLo[az];
      nextLo[az] = nextLo[bz];
      nextLo[bz] = tz;
      tz = nextHi[az];
      nextHi[az] = nextHi[bz];
      nextHi[bz] = tz;
      tz = nextD[az];
      nextD[az] = nextD[bz];
      nextD[bz] = tz;
    }

    mpush(loSt, hiSt, dSt);

    while (sp > 0) {
      _assert(sp < MAIN_QSORT_STACK_SIZE - 2);

      sp--;
      int lo = stackLo[sp];
      int hi = stackHi[sp];
      int d = stackD[sp];

      if (hi - lo < MAIN_QSORT_SMALL_THRESH || d > MAIN_QSORT_DEPTH_THRESH) {
        _mainSimpleSort(ptr, block, quadrant, nblock, lo, hi, d);
        if (_budget < 0) {
          return;
        }
        continue;
      }

      int med = mmed3(block[ptr[lo] + d],
                      block[ptr[hi] + d],
                      block[ptr[(lo + hi) >> 1] + d]);

      int unLo = lo;
      int ltLo = lo;
      int unHi = hi;
      int gtHi = hi;

      while (true) {
        while (true) {
          if (unLo > unHi) {
            break;
          }

          int n = (block[ptr[unLo] + d]) - med;
          if (n == 0) {
            int t = ptr[unLo];
            ptr[unLo] = ptr[ltLo];
            ptr[ltLo] = t;
            ltLo++;
            unLo++;
            continue;
          }
          if (n >  0) {
            break;
          }
          unLo++;
        }
        while (true) {
          if (unLo > unHi) {
            break;
          }

          int n = (block[ptr[unHi] + d]) - med;
          if (n == 0) {
            int t = ptr[unHi];
            ptr[unHi] = ptr[gtHi];
            ptr[gtHi] = t;
            gtHi--;
            unHi--;
            continue;
          }
          if (n <  0) {
            break;
          }
          unHi--;
        }
        if (unLo > unHi) {
          break;
        }

        int t = ptr[unLo];
        ptr[unLo] = ptr[unHi];
        ptr[unHi] = t;
        unLo++;
        unHi--;
      }

      _assert(unHi == unLo - 1);

      if (gtHi < ltLo) {
        mpush(lo, hi, d+1 );
        continue;
      }

      int n = mmin(ltLo - lo, unLo - ltLo);
      mvswap(lo, unLo - n, n);
      int m = mmin(hi - gtHi, gtHi - unHi);
      mvswap(unLo, hi - m + 1, m);

      n = lo + unLo - ltLo - 1;
      m = hi - (gtHi - unHi) + 1;

      nextLo[0] = lo;
      nextHi[0] = n;
      nextD[0] = d;
      nextLo[1] = m;
      nextHi[1] = hi;
      nextD[1] = d;
      nextLo[2] = n + 1;
      nextHi[2] = m - 1;
      nextD[2] = d + 1;

      if (mnextsize(0) < mnextsize(1)) {
        mnextswap(0, 1);
      }
      if (mnextsize(1) < mnextsize(2)) {
        mnextswap(1, 2);
      }
      if (mnextsize(0) < mnextsize(1)) {
        mnextswap(0, 1);
      }

      _assert(mnextsize(0) >= mnextsize(1));
      _assert(mnextsize(1) >= mnextsize(2));

      mpush(nextLo[0], nextHi[0], nextD[0]);
      mpush(nextLo[1], nextHi[1], nextD[1]);
      mpush(nextLo[2], nextHi[2], nextD[2]);
    }
  }

  void _mainSimpleSort(Uint32List ptr, Uint8List block,
                      Uint16List quadrant,
                      int nblock, int lo, int hi, int d) {
    int bigN = hi - lo + 1;
    if (bigN < 2) {
      return;
    }

    const List<int> incs = const [
        1, 4, 13, 40, 121, 364, 1093, 3280, 9841, 29524, 88573, 265720,
        797161, 2391484];

    int hp = 0;
    while (incs[hp] < bigN) {
      hp++;
    }
    hp--;

    for (; hp >= 0; hp--) {
      int h = incs[hp];

      int i = lo + h;
      while (true) {
        // copy 1
        if (i > hi) {
          break;
        }
        int v = ptr[i];
        int j = i;
        while (_mainGtU(ptr[j - h] + d, v + d, block, quadrant, nblock)) {
          ptr[j] = ptr[j - h];
          j = j - h;
          if (j <= (lo + h - 1)) {
            break;
          }
        }
        ptr[j] = v;
        i++;

        // copy 2
        if (i > hi) {
          break;
        }
        v = ptr[i];
        j = i;
        while (_mainGtU(ptr[j - h] + d, v + d, block, quadrant, nblock)) {
          ptr[j] = ptr[j - h];
          j = j - h;
          if (j <= (lo + h - 1)) {
            break;
          }
        }
        ptr[j] = v;
        i++;

        // copy 3
        if (i > hi) {
          break;
        }
        v = ptr[i];
        j = i;
        while (_mainGtU(ptr[j - h] + d, v + d, block, quadrant, nblock)) {
          ptr[j] = ptr[j - h];
          j = j - h;
          if (j <= (lo + h - 1)) {
            break;
          }
        }
        ptr[j] = v;
        i++;

        if (_budget < 0) {
          return;
        }
      }
    }
  }

  bool _mainGtU(int i1, int i2, Uint8List block,
                Uint16List quadrant, int nblock) {
    _assert(i1 != i2);
    // 1
    int c1 = block[i1];
    int c2 = block[i2];
    if (c1 != c2) {
      return (c1 > c2);
    }
    i1++;
    i2++;
    // 2
    c1 = block[i1];
    c2 = block[i2];
    if (c1 != c2) {
      return (c1 > c2);
    }
    i1++;
    i2++;
    // 3
    c1 = block[i1];
    c2 = block[i2];
    if (c1 != c2) {
      return (c1 > c2);
    }
    i1++;
    i2++;
    // 4
    c1 = block[i1];
    c2 = block[i2];
    if (c1 != c2) {
      return (c1 > c2);
    }
    i1++;
    i2++;
    // 5
    c1 = block[i1];
    c2 = block[i2];
    if (c1 != c2) {
      return (c1 > c2);
    }
    i1++;
    i2++;
    // 6
    c1 = block[i1];
    c2 = block[i2];
    if (c1 != c2) {
      return (c1 > c2);
    }
    i1++;
    i2++;
    // 7
    c1 = block[i1];
    c2 = block[i2];
    if (c1 != c2) {
      return (c1 > c2);
    }
    i1++;
    i2++;
    // 8
    c1 = block[i1];
    c2 = block[i2];
    if (c1 != c2) {
      return (c1 > c2);
    }
    i1++;
    i2++;
    // 9
    c1 = block[i1];
    c2 = block[i2];
    if (c1 != c2) {
      return (c1 > c2);
    }
    i1++;
    i2++;
    // 10
    c1 = block[i1];
    c2 = block[i2];
    if (c1 != c2) {
      return (c1 > c2);
    }
    i1++;
    i2++;
    // 11
    c1 = block[i1];
    c2 = block[i2];
    if (c1 != c2) {
      return (c1 > c2);
    }
    i1++;
    i2++;
    // 12
    c1 = block[i1];
    c2 = block[i2];
    if (c1 != c2) {
      return (c1 > c2);
    }
    i1++;
    i2++;

    int k = nblock + 8;

    do {
      // 1
      c1 = block[i1];
      c2 = block[i2];
      if (c1 != c2) {
        return (c1 > c2);
      }
      int s1 = quadrant[i1];
      int s2 = quadrant[i2];
      if (s1 != s2) {
        return (s1 > s2);
      }
      i1++;
      i2++;
      // 2
      c1 = block[i1];
      c2 = block[i2];
      if (c1 != c2) {
        return (c1 > c2);
      }
      s1 = quadrant[i1];
      s2 = quadrant[i2];
      if (s1 != s2) {
        return (s1 > s2);
      }
      i1++;
      i2++;
      // 3
      c1 = block[i1];
      c2 = block[i2];
      if (c1 != c2) {
        return (c1 > c2);
      }
      s1 = quadrant[i1];
      s2 = quadrant[i2];
      if (s1 != s2) {
        return (s1 > s2);
      }
      i1++;
      i2++;
      // 4
      c1 = block[i1];
      c2 = block[i2];
      if (c1 != c2) {
        return (c1 > c2);
      }
      s1 = quadrant[i1];
      s2 = quadrant[i2];
      if (s1 != s2) {
        return (s1 > s2);
      }
      i1++;
      i2++;
      // 5
      c1 = block[i1];
      c2 = block[i2];
      if (c1 != c2) {
        return (c1 > c2);
      }
      s1 = quadrant[i1];
      s2 = quadrant[i2];
      if (s1 != s2) {
        return (s1 > s2);
      }
      i1++;
      i2++;
      // 6
      c1 = block[i1];
      c2 = block[i2];
      if (c1 != c2) {
        return (c1 > c2);
      }
      s1 = quadrant[i1];
      s2 = quadrant[i2];
      if (s1 != s2) {
        return (s1 > s2);
      }
      i1++;
      i2++;
      // 7
      c1 = block[i1];
      c2 = block[i2];
      if (c1 != c2) {
        return (c1 > c2);
      }
      s1 = quadrant[i1];
      s2 = quadrant[i2];
      if (s1 != s2) {
        return (s1 > s2);
      }
      i1++;
      i2++;
      // 8
      c1 = block[i1];
      c2 = block[i2];
      if (c1 != c2) {
        return (c1 > c2);
      }
      s1 = quadrant[i1];
      s2 = quadrant[i2];
      if (s1 != s2) {
        return (s1 > s2);
      }
      i1++;
      i2++;

      if (i1 >= nblock) {
        i1 -= nblock;
      }
      if (i2 >= nblock) {
        i2 -= nblock;
      }

      k -= 8;
      _budget--;
    } while (k >= 0);

    return false;
  }


  void _addCharToBlock(int b) {
    if (b != _state_in_ch && _state_in_len == 1) {
      _blockCRC = BZip2.updateCrc(_state_in_ch, _blockCRC);
      _inUse[_state_in_ch] = 1;
      _block[_nblock] = _state_in_ch;
      _nblock++;
      _state_in_ch = b;
    } else {
      if (b != _state_in_ch || _state_in_len == 255) {
        if (_state_in_ch < 256) {
          _addPairToBlock();
        }
        _state_in_ch = b;
        _state_in_len = 1;
      } else {
        _state_in_len++;
      }
    }
  }

  void _addPairToBlock() {
    for (int i = 0; i < _state_in_len; i++) {
      _blockCRC = BZip2.updateCrc(_state_in_ch, _blockCRC);
    }
    _inUse[_state_in_ch] = 1;
    switch (_state_in_len) {
      case 1:
         _block[_nblock] = _state_in_ch;
         _nblock++;
         break;
      case 2:
         _block[_nblock] = _state_in_ch;
         _nblock++;
         _block[_nblock] = _state_in_ch;
         _nblock++;
         break;
      case 3:
         _block[_nblock] = _state_in_ch;
         _nblock++;
         _block[_nblock] = _state_in_ch;
         _nblock++;
         _block[_nblock] = _state_in_ch;
         _nblock++;
         break;
      default:
         _inUse[_state_in_len - 4] = 1;
         _block[_nblock] = _state_in_ch;
         _nblock++;
         _block[_nblock] = _state_in_ch;
         _nblock++;
         _block[_nblock] = _state_in_ch;
         _nblock++;
         _block[_nblock] = _state_in_ch;
         _nblock++;
         _block[_nblock] = _state_in_len - 4;
         _nblock++;
         break;
    }
  }

  InputStream input;
  Bz2BitWriter bw;
  int _nblockMax;
  int _state_in_ch;
  int _state_in_len;
  int _nblock;
  int _blockCRC;
  int _blockNo; // ignore: unused_field
  int _workFactor;
  int _budget;
  int _origPtr;

  Uint32List _arr1;
  Uint32List _arr2;
  Uint32List _ftab;
  Uint8List _block;
  Uint8List _inUse;
  Uint16List _mtfv;
  int _nInUse;

  int _nMTF;
  Int32List _mtfFreq;
  Uint8List _unseqToSeq;
  List<Uint8List> _len;
  List<Int32List> _code;
  List<Int32List> _rfreq;
  List<Uint32List> _lenPack;
  Uint8List _selector;
  Uint8List _selectorMtf;

  static const int BZ_N_RADIX = 2;
  static const int BZ_N_QSORT = 12;
  static const int BZ_N_SHELL = 18;
  static const int BZ_N_OVERSHOOT = (BZ_N_RADIX + BZ_N_QSORT + BZ_N_SHELL + 2);
  static const int BZ_MAX_ALPHA_SIZE = 258;
  static const int BZ_RUNA = 0;
  static const int BZ_RUNB = 1;
  static const int BZ_N_GROUPS = 6;
  static const int BZ_G_SIZE = 50;
  static const int BZ_N_ITERS = 4;
  static const int BZ_LESSER_ICOST = 0;
  static const int BZ_GREATER_ICOST = 15;
  static const int BZ_MAX_SELECTORS = (2 + (900000 ~/ BZ_G_SIZE));
}

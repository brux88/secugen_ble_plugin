import 'dart:typed_data';

import 'package:secugen_ble_plugin/utils/fmsheader.dart';

class FMSData {
  late Uint8List dData;
  int dLength = 0;

  FMSData();

  FMSData.fromBytes(Uint8List bytes) {
    FMSHeader header = FMSHeader.fromBuffer(bytes);
    if (header.pktCommand == 67) {
      set(bytes, (header.pktDatasize2 << 16) | header.pktDatasize1);
    } else {
      set(bytes, header.pktDatasize1);
    }
  }

  void set(Uint8List bytes, int length) {
    dLength = length;
    dData = Uint8List(length);
    dData.setRange(0, length, bytes.skip(12));
  }

  Uint8List get() {
    return dData;
  }
}

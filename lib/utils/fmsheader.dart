import 'dart:typed_data';

class FMSHeader {
  int pktClass = 0;
  int pktCommand = 0;
  int pktParam1 = 0;
  int pktParam2 = 0;
  int pktDatasize1 = 0;
  int pktDatasize2 = 0;
  int pktError = 0;
  int pktChecksum = 0;

  FMSHeader();

  FMSHeader.fromBuffer(Uint8List buffer, {bool calcChecksum = false}) {
    set(buffer, calcChecksum: calcChecksum);
  }

  void set(Uint8List buffer, {bool calcChecksum = false}) {
    pktClass = buffer[0];
    pktCommand = buffer[1];
    pktParam1 = buffer[2] | (buffer[3] << 8);
    pktParam2 = buffer[4] | (buffer[5] << 8);
    pktDatasize1 = buffer[6] | (buffer[7] << 8);
    pktDatasize2 = buffer[8] | (buffer[9] << 8);
    pktError = buffer[10];
    if (calcChecksum) {
      pktChecksum = _getCheckSum(get(), 11);
    } else {
      pktChecksum = buffer[11];
    }
  }

  Uint8List get() {
    final buffer = Uint8List(12);
    buffer[0] = pktClass;
    buffer[1] = pktCommand;
    buffer[2] = pktParam1 & 0xFF;
    buffer[3] = (pktParam1 >> 8) & 0xFF;
    buffer[4] = pktParam2 & 0xFF;
    buffer[5] = (pktParam2 >> 8) & 0xFF;
    buffer[6] = pktDatasize1 & 0xFF;
    buffer[7] = (pktDatasize1 >> 8) & 0xFF;
    buffer[8] = pktDatasize2 & 0xFF;
    buffer[9] = (pktDatasize2 >> 8) & 0xFF;
    buffer[10] = pktError;
    buffer[11] = pktChecksum;
    return buffer;
  }

  int getExtraDataSize() {
    return (pktDatasize1 & 0x0000FFFF) | ((pktDatasize2 << 16) & 0xFFFF0000);
  }

  void setCheckSum() {
    pktChecksum = _getCheckSum(get(), 11);
  }

  int _getCheckSum(Uint8List buffer, int buffLength) {
    int checksum = 0;
    for (int i = 0; i < buffLength; i++) {
      checksum = (checksum + buffer[i]) & 0xFF;
    }
    return checksum;
  }
}

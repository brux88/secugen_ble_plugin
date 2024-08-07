import 'dart:typed_data';

import 'secugen_ble_plugin_platform_interface.dart';

class SecugenBlePlugin {
  Future<String?> getPlatformVersion() {
    return SecugenBlePluginPlatform.instance.getPlatformVersion();
  }

  Future<String?> getVersion() {
    return SecugenBlePluginPlatform.instance.getVersion();
  }

  Future<void> makeRecordStart(int fingerNumber) {
    return SecugenBlePluginPlatform.instance.makeRecordStart(fingerNumber);
  }

  Future<void> makeRecordCont(int fingerNumber) {
    return SecugenBlePluginPlatform.instance.makeRecordCont(fingerNumber);
  }

  Future<void> makeRecordEnd() {
    return SecugenBlePluginPlatform.instance.makeRecordEnd();
  }

  Future<void> loadMatchTemplate(int extraDataSize) {
    return SecugenBlePluginPlatform.instance.loadMatchTemplate(extraDataSize);
  }

  Future<void> loadMatchTemplateWithExtraData(
      {required int extraDataSize, required Uint8List extraData}) async {
    return SecugenBlePluginPlatform.instance
        .loadMatchTemplateWithExtraData(extraDataSize, extraData);
  }
}

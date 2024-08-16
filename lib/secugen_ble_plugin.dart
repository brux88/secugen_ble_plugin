import 'dart:ffi';
import 'dart:typed_data';

import 'secugen_ble_plugin_platform_interface.dart';

class SecugenBlePlugin {
  Future<List<int>> getVersion() {
    return SecugenBlePluginPlatform.instance.getVersion();
  }

  Future<String?> parseResponse(List<int> bytes) {
    return SecugenBlePluginPlatform.instance.parseResponse(bytes);
  }

  Future<List<int>> getTemplate() {
    return SecugenBlePluginPlatform.instance.getTemplate();
  }

  Future<List<int>> instantVerifyExtraData(
      {required int numberOfTemplate,
      required int extraDataSize,
      required Uint8List extraData}) async {
    return SecugenBlePluginPlatform.instance
        .instantVerifyExtraData(numberOfTemplate, extraDataSize, extraData);
  }
}

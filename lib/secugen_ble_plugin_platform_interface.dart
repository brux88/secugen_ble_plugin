import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'secugen_ble_plugin_method_channel.dart';

abstract class SecugenBlePluginPlatform extends PlatformInterface {
  /// Constructs a SecugenBlePluginPlatform.
  SecugenBlePluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static SecugenBlePluginPlatform _instance = MethodChannelSecugenBlePlugin();

  /// The default instance of [SecugenBlePluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelSecugenBlePlugin].
  static SecugenBlePluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SecugenBlePluginPlatform] when
  /// they register themselves.
  static set instance(SecugenBlePluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> getVersion() {
    throw UnimplementedError('Version() has not been implemented.');
  }

  Future<void> makeRecordStart(int fingerNumber) {
    throw UnimplementedError('makeRecordStart() has not been implemented.');
  }

  Future<void> makeRecordCont(int fingerNumber) {
    throw UnimplementedError('makeRecordCont() has not been implemented.');
  }

  Future<void> makeRecordEnd() {
    throw UnimplementedError('makeRecordEnd() has not been implemented.');
  }

  Future<void> loadMatchTemplate(int extraDataSize) {
    throw UnimplementedError('loadMatchTemplate() has not been implemented.');
  }

  Future<void> loadMatchTemplateWithExtraData(
      int extraDataSize, Uint8List extraData) {
    throw UnimplementedError(
        'loadMatchTemplateWithExtraData() has not been implemented.');
  }
}

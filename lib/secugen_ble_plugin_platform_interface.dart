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

  Future<String?> parseResponse(List<int> bytes) {
    throw UnimplementedError('parseResponse() has not been implemented.');
  }

  Future<List<int>> getVersion() {
    throw UnimplementedError('Version() has not been implemented.');
  }

  Future<List<int>> setPowerOffTime2H() {
    throw UnimplementedError('setPowerOffTime2H() has not been implemented.');
  }

  Future<List<int>> getTemplate() {
    throw UnimplementedError('getTemplate() has not been implemented.');
  }

  Future<List<int>> instantVerifyExtraData(
      int numberOfTemplate, int extraDataSize, Uint8List extraData) {
    throw UnimplementedError(
        'instantVerifyExtraData() has not been implemented.');
  }
}

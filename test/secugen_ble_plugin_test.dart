import 'package:flutter_test/flutter_test.dart';
import 'package:secugen_ble_plugin/secugen_ble_plugin.dart';
import 'package:secugen_ble_plugin/secugen_ble_plugin_platform_interface.dart';
import 'package:secugen_ble_plugin/secugen_ble_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSecugenBlePluginPlatform
    with MockPlatformInterfaceMixin
    implements SecugenBlePluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SecugenBlePluginPlatform initialPlatform = SecugenBlePluginPlatform.instance;

  test('$MethodChannelSecugenBlePlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSecugenBlePlugin>());
  });

  test('getPlatformVersion', () async {
    SecugenBlePlugin secugenBlePlugin = SecugenBlePlugin();
    MockSecugenBlePluginPlatform fakePlatform = MockSecugenBlePluginPlatform();
    SecugenBlePluginPlatform.instance = fakePlatform;

    expect(await secugenBlePlugin.getPlatformVersion(), '42');
  });
}

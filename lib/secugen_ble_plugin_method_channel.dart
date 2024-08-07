import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:secugen_ble_plugin/utils/SgfplibException_exception.dart';

import 'secugen_ble_plugin_platform_interface.dart';
import 'utils/constants.dart';

/// An implementation of [SecugenBlePluginPlatform] that uses method channels.
class MethodChannelSecugenBlePlugin extends SecugenBlePluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('secugen_ble_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> makeRecordStart(int fingerNumber) async {
    try {
      await methodChannel.invokeMethod(METHOD_MAKE_RECORD_START, fingerNumber);
    } on PlatformException catch (e) {
      throw _libException(e);
    }
  }

  @override
  Future<void> makeRecordCont(int fingerNumber) async {
    try {
      await methodChannel.invokeMethod(METHOD_MAKE_RECORD_CONT, fingerNumber);
    } on PlatformException catch (e) {
      throw _libException(e);
    }
  }

  @override
  Future<void> makeRecordEnd() async {
    try {
      await methodChannel.invokeMethod(METHOD_MAKE_RECORD_END);
    } on PlatformException catch (e) {
      throw _libException(e);
    }
  }

  @override
  Future<void> loadMatchTemplate(int extraDataSize) async {
    try {
      await methodChannel.invokeMethod(
          METHOD_LOAD_MATCH_TEMPLATE, extraDataSize);
    } on PlatformException catch (e) {
      throw _libException(e);
    }
  }

  @override
  Future<void> loadMatchTemplateWithExtraData(
      int extraDataSize, Uint8List extraData) async {
    try {
      await methodChannel.invokeMethod(
          METHOD_LOAD_MATCH_TEMPLATE_WITH_EXTRADATA,
          [extraDataSize, extraData]);
    } on PlatformException catch (e) {
      throw _libException(e);
    }
  }

  @override
  Future<String?> getVersion() async {
    final version =
        await methodChannel.invokeMethod<String>(METHOD_GET_VERSION);
    return version;
  }

  SgfplibException _libException(PlatformException exception) {
    SgfplibException sgfplibException = SgfplibException();

    switch (exception.code) {
      case ERROR_NOT_SUPPORTED:
        sgfplibException =
            DeviceNotSupportedException(message: exception.message);
        break;

      case ERROR_INITIALIZATION_FAILED:
        sgfplibException =
            InitializationFailedException(message: exception.message);
        break;

      case ERROR_SENSOR_NOT_FOUND:
        sgfplibException = SensorNotFoundException(message: exception.message);
        break;

      case ERROR_SMART_CAPTURE_ENABLED:
        sgfplibException =
            SmartCaptureEnabledException(message: exception.message);
        break;

      case ERROR_OUT_OF_RANGE:
        sgfplibException = OutOfRangeException(message: exception.message);
        break;

      case ERROR_NO_FINGERPRINT:
        sgfplibException = NoFingerprintException(message: exception.message);
        break;

      case ERROR_TEMPLATE_INITIALIZE_FAILED:
        sgfplibException =
            TemplateInitializationException(message: exception.message);
        break;

      case ERROR_TEMPLATE_MATCHING_FAILED:
        sgfplibException =
            TemplateMatchingException(message: exception.message);
        break;
    }

    return sgfplibException;
  }
}

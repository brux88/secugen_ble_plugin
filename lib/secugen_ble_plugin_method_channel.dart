import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:secugen_ble_plugin/utils/SgfplibException_exception.dart';

import 'secugen_ble_plugin_platform_interface.dart';
import 'utils/constants.dart';

class MethodChannelSecugenBlePlugin extends SecugenBlePluginPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('secugen_ble_plugin');

  @override
  Future<List<int>> instantVerifyExtraData(
      int numberOfTemplate, int extraDataSize, Uint8List extraData) async {
    try {
      final instatVerify = await methodChannel.invokeMethod(
          METHOD_INSTANT_VERIFY_WITH_EXTRADATA,
          [numberOfTemplate, extraDataSize, extraData]);
      return instatVerify;
    } on PlatformException catch (e) {
      throw _libException(e);
    }
  }

  @override
  Future<String?> parseResponse(List<int> bytes) async {
    try {
      var result = await methodChannel.invokeMethod<String?>(
          METHOD_PARSE_RESPONSE, bytes);
      return result;
    } on PlatformException catch (e) {
      throw _libException(e);
    }
  }

  @override
  Future<List<int>> getTemplate() async {
    try {
      final template = await methodChannel.invokeMethod(METHOD_GET_TEMPLATE);
      return template;
    } on PlatformException catch (e) {
      throw _libException(e);
    }
  }

  @override
  Future<List<int>> getVersion() async {
    final version = await methodChannel.invokeMethod(METHOD_GET_VERSION);
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

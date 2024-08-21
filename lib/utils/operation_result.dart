import 'package:secugen_ble_plugin/utils/teamplate_nfc.dart';

class OperationResult {
  final bool isSuccess;
  final String message;
  final int? errorCode;
  final TemplateNFC? payloadNfc;
  OperationResult.success(this.message, [this.payloadNfc])
      : isSuccess = true,
        errorCode = null;

  OperationResult.error(this.message, [this.payloadNfc, this.errorCode])
      : isSuccess = false;
}

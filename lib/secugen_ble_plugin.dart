import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:secugen_ble_plugin/utils/enum.dart';
import 'package:secugen_ble_plugin/utils/fmsdata.dart';
import 'package:secugen_ble_plugin/utils/fmsheader.dart';
import 'package:secugen_ble_plugin/utils/fmstemplatefile.dart';
import 'package:secugen_ble_plugin/utils/operation_result.dart';
import 'package:secugen_ble_plugin/utils/teamplate_nfc.dart';
import 'secugen_ble_plugin_platform_interface.dart';
import 'package:ndef/ndef.dart' as ndef;

class SecugenBlePlugin {
  Completer<OperationResult>? _completerRegisterFingerPrint;
  Completer<OperationResult>? _completerVerifyFingerPrint;
  Completer<OperationResult>? _completerVersionDevice;
  Completer<OperationResult>? _completerSetPowerOffTime2H;
  Completer<OperationResult>? _completerSetVerifySecurityLowLevel;
  Completer<OperationResult>? _completerGetSystemInfoSecurityLevel;
  Completer<OperationResult>? _completerWriteNfc;
  Completer<OperationResult>? _completerReadNfc;

  // Stream controller per aggiornamenti dello stato
  StreamController<NfcOperationStatus> _statusStreamController =
      StreamController<NfcOperationStatus>.broadcast();

  //Stream<NfcOperationStatus> get statusStream => _statusStreamController.stream;

  Stream<NfcOperationStatus> get statusStream {
    if (_statusStreamController.isClosed) {
      _statusStreamController =
          StreamController<NfcOperationStatus>.broadcast();
    }
    return _statusStreamController.stream;
  }

  bool _isRegisterFingerPrintCompleted = false;
  bool _isVerifyFingerPrintCompleted = false;
  bool _isSetPowerOffTime2HCompleted = false;
  bool _isSetVerifySecurityLowLevelCompleted = false;
  bool _isGetSystemInfoSecurityLevelCompleted = false;
  bool _isVersionDeviceCompleted = false;
  bool _isWriteNfcCompleted = false;
  bool _isReadNfcCompleted = false;

  Uint8List mOneTemplateBuf = Uint8List(400);
  int mOneTemplateSize = 0;
  int mBytesRead = 0;
  int mRemainingSize = 0;
  int mCurrentCommand = 0;
  static const int errNone = 0x00; // Nomrale Operazione
  static const int errVerifyFailed =
      0x04; // Errore di verifica dell'impronta digitale
  static const int errTimeout =
      0x08; // Errore di verifica dell'impronta digitale
  static const int errInvalidFormat = 0x30; //  Record format is invalid
  StreamController<String> _logController =
      StreamController<String>.broadcast();
  Stream<String> get logStream => _logController.stream;
  ValueNotifier<int> progressNotifier = ValueNotifier<int>(0);

  String SECUGEN_MAC_ADDRESS = "CC:35:5A";

  static const int PACKET_HEADER_SIZE = 12;
  static const int IMG_WIDTH_MAX = 300;
  static const int PK_COMMAND_CAPTURE = 67;
  static const int PK_COMMAND_VERIFY = 208;
  static const int PK_COMMAND_VERSION = 5;
  static const int PK_COMMAND_SET_POWER_OFF_2H = 247;
  static const int PK_COMMAND_SET_LEVEL_SECURITY_LOW = 0X20;
  static const int PK_COMMAND_GET_LEVEL_SECURITY = 0X30;
  static const int PK_COMMAND_TEMPLATE = 64;
  static const int IMG_HEIGHT_MAX = 400;
  static const int IMG_SIZE_MAX = (IMG_WIDTH_MAX * IMG_HEIGHT_MAX);
  static Uuid CHARACTERISTIC_READ_NOTIFY =
      Uuid.parse("00002bb1-0000-1000-8000-00805f9b34fb");
  Uuid CHARACTERISTIC_WRITE =
      Uuid.parse("00002bb2-0000-1000-8000-00805f9b34fb");
  Uuid SERVICE_SECUGEN_SPP_OVER_BLE =
      Uuid.parse("0000fda0-0000-1000-8000-00805f9b34fb");
  List<int> mTransferBuffer =
      List<int>.filled(PACKET_HEADER_SIZE + IMG_SIZE_MAX + 1, 0);

  Future<List<int>> getVersion() {
    return SecugenBlePluginPlatform.instance.getVersion();
  }

  Future<List<int>> setPowerOffTime2H() {
    return SecugenBlePluginPlatform.instance.setPowerOffTime2H();
  }

  Future<List<int>> getSystemInfoSecurityLevel() {
    return SecugenBlePluginPlatform.instance.getVerifySecurityLevel();
  }

  Future<List<int>> setVerifySecurityLowLevel() {
    return SecugenBlePluginPlatform.instance.setVerifySecurityLowLevel();
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

  Future<OperationResult> getFingerPrintTemplate(
      FlutterReactiveBle ble, String deviceId) async {
    startNewRegisterFingerPrintOperation();

    mTransferBuffer =
        List<int>.filled(PACKET_HEADER_SIZE + IMG_SIZE_MAX + 1, 0);

    final characteristicWrite = QualifiedCharacteristic(
        serviceId: SERVICE_SECUGEN_SPP_OVER_BLE,
        characteristicId: CHARACTERISTIC_WRITE,
        deviceId: deviceId);

    await ble.writeCharacteristicWithResponse(characteristicWrite,
        value: await getTemplate());
    return _completerRegisterFingerPrint!.future;
  }

  void updateProgress(int progress) {
    progressNotifier.value = progress;
  }

// Metodi per aggiungere e gestire lo stato
  void _sendStatusUpdateNfc(NfcOperationStatus status) {
    // Verifica se il StreamController è chiuso
    if (_statusStreamController.isClosed) {
      // Se è chiuso, ri-inizializza
      _initializeStatusStreamController();
    }

    if (!_statusStreamController.isClosed) {
      _statusStreamController.add(status);
    }
  }

  // Metodo per inizializzare il StreamController
  void _initializeStatusStreamController() {
    if (_statusStreamController.isClosed) {
      _statusStreamController =
          StreamController<NfcOperationStatus>.broadcast();
    }
  }

  // Metodo per inizializzare il StreamController
  void _initializeLogController() {
    if (_logController.isClosed) {
      _logController = StreamController<String>.broadcast();
    }
  }

  void addLog(String message) {
    print(message);
    // Verifica se il StreamController è chiuso
    if (_logController.isClosed) {
      // Se è chiuso, ri-inizializza
      _initializeLogController();
    }

    _logController.add(message);
  }

  void cancelPendingOperations() {
    // Completa i completer con un errore o cancella se non sono già completati
    if (_isRegisterFingerPrintCompleted &&
        _completerRegisterFingerPrint != null) {
      _completerRegisterFingerPrint = null;
      _isRegisterFingerPrintCompleted = false;
    }

    if (_isVerifyFingerPrintCompleted && _completerVerifyFingerPrint != null) {
      _completerVerifyFingerPrint = null;
      _isVerifyFingerPrintCompleted = false;
    }

    if (_isVersionDeviceCompleted && _completerVersionDevice != null) {
      _completerVersionDevice = null;
      _isVersionDeviceCompleted = false;
    }

    if (_isSetPowerOffTime2HCompleted && _completerSetPowerOffTime2H != null) {
      _completerSetPowerOffTime2H = null;
      _isSetPowerOffTime2HCompleted = false;
    }
    if (_isSetVerifySecurityLowLevelCompleted &&
        _completerSetVerifySecurityLowLevel != null) {
      _completerSetVerifySecurityLowLevel = null;
      _isSetVerifySecurityLowLevelCompleted = false;
    }
    if (_isGetSystemInfoSecurityLevelCompleted &&
        _completerGetSystemInfoSecurityLevel != null) {
      _completerGetSystemInfoSecurityLevel = null;
      _isGetSystemInfoSecurityLevelCompleted = false;
    }
    if (_isWriteNfcCompleted && _completerWriteNfc != null) {
      _completerWriteNfc = null;
      _isWriteNfcCompleted = false;
    }

    if (_isReadNfcCompleted && _completerReadNfc != null) {
      _completerReadNfc = null;
      _isReadNfcCompleted = false;
    }
  }

  void startNewRegisterFingerPrintOperation() {
    // Reset the completer and the flag for a new operation
    _completerRegisterFingerPrint = Completer<OperationResult>();
    _isRegisterFingerPrintCompleted = false;
    progressNotifier = ValueNotifier<int>(0);
  }

  void startNewWriteNfcOperation() {
    _completerWriteNfc = Completer<OperationResult>();
    _isWriteNfcCompleted = false;
  }

  void startNewReadNfcOperation() {
    _completerReadNfc = Completer<OperationResult>();
    _isReadNfcCompleted = false;
  }

  void startNewVerifyFingerPrintOperation() {
    _completerVerifyFingerPrint = Completer<OperationResult>();
    _isVerifyFingerPrintCompleted = false;
  }

  void startNewVersionDeviceOperation() {
    _completerVersionDevice = Completer<OperationResult>();
    _isVersionDeviceCompleted = false;
  }

  void startNewSetPowerOffTime2HOperation() {
    _completerSetPowerOffTime2H = Completer<OperationResult>();
    _isSetPowerOffTime2HCompleted = false;
  }

  void startNewSetVerifySecurityLowLevelOperation() {
    _completerSetVerifySecurityLowLevel = Completer<OperationResult>();
    _isSetVerifySecurityLowLevelCompleted = false;
  }

  void startNewGetSystemInfoSecurityLevelOperation() {
    _completerGetSystemInfoSecurityLevel = Completer<OperationResult>();
    _isGetSystemInfoSecurityLevelCompleted = false;
  }

  // Metodo per completare il completer in sicurezza
  void completeRegisterFingerPrint(OperationResult result) {
    if (!_isRegisterFingerPrintCompleted) {
      _completerRegisterFingerPrint?.complete(result);
      print('Completing Completer with result: $result');

      _isRegisterFingerPrintCompleted = true;
    }
  }

  void completeVerifyFingerPrint(OperationResult result) {
    if (!_isVerifyFingerPrintCompleted) {
      _completerVerifyFingerPrint?.complete(result);
      _isVerifyFingerPrintCompleted = true;
    }
  }

  void completeVersionDevice(OperationResult result) {
    if (!_isVersionDeviceCompleted) {
      _completerVersionDevice?.complete(result);
      _isVersionDeviceCompleted = true;
    }
  }

  void completeSetPowerOff2H(OperationResult result) {
    if (!_isSetPowerOffTime2HCompleted) {
      _completerSetPowerOffTime2H?.complete(result);
      _isSetPowerOffTime2HCompleted = true;
    }
  }

  void completeSetVerifySecurityLowLevel(OperationResult result) {
    if (!_isSetVerifySecurityLowLevelCompleted) {
      _completerSetVerifySecurityLowLevel?.complete(result);
      _isSetVerifySecurityLowLevelCompleted = true;
    }
  }

  void completeGetSystemInfoSecurityLevel(OperationResult result) {
    if (!_isGetSystemInfoSecurityLevelCompleted) {
      _completerGetSystemInfoSecurityLevel?.complete(result);
      _isGetSystemInfoSecurityLevelCompleted = true;
    }
  }

  void completeWriteNfc(OperationResult result) {
    if (!_isWriteNfcCompleted) {
      _completerWriteNfc?.complete(result);
      _isWriteNfcCompleted = true;
    }
  }

  void completeReadNfc(OperationResult result) {
    if (!_isReadNfcCompleted) {

      _completerReadNfc?.complete(result);
      _isReadNfcCompleted = true;
    }
  }

  Future<void> enableNotifications(
      FlutterReactiveBle ble, String deviceId) async {
    try {
      final characteristic = QualifiedCharacteristic(
          serviceId: SERVICE_SECUGEN_SPP_OVER_BLE,
          characteristicId: CHARACTERISTIC_READ_NOTIFY,
          deviceId: deviceId);
      ble.subscribeToCharacteristic(characteristic).listen((data) {
        processCharacteristicData(ble, data, characteristic.characteristicId,
            characteristic.deviceId);
      });
    } catch (e) {
      addLog("Error enabling notifications: $e");
    }
  }

  void processCharacteristicData(FlutterReactiveBle ble, List<int> data,
      Uuid characteristicId, String deviceId) async {
    if (characteristicId == CHARACTERISTIC_READ_NOTIFY) {
      if (data.isNotEmpty &&
          data.length == PACKET_HEADER_SIZE &&
          data[0] == 0x4E) {
        readCustomCharacteristic(ble, deviceId);
        return;
      }

      if (data.isNotEmpty) {
        if (data.length == PACKET_HEADER_SIZE) {
          Uint8List buffer = Uint8List.fromList(data);

          var header = FMSHeader.fromBuffer(buffer);
          mCurrentCommand = header.pktCommand;
          int nExtraDataSize = header.getExtraDataSize();

          if (nExtraDataSize > 0 &&
              header.pktChecksum == data[PACKET_HEADER_SIZE - 1]) {
            mRemainingSize = PACKET_HEADER_SIZE + nExtraDataSize;
            mBytesRead = 0;
          }
        }

        if (mRemainingSize > 0) {
          mTransferBuffer.setRange(mBytesRead, mBytesRead + data.length, data);
          mRemainingSize -= data.length;
          mBytesRead += data.length;
          addLog("mRemainingSize:  $mRemainingSize");
          addLog('mBytesRead: $mBytesRead');
          addLog('data.length: ${data.length}');
          addLog('mTransferBuffer length: ${mTransferBuffer.length}');
          addLog(
              ((mBytesRead * 100) ~/ (mRemainingSize + mBytesRead)).toString());

          if (mRemainingSize > 0) {
            updateProgress(
                ((mBytesRead * 100) ~/ (mRemainingSize + mBytesRead)));

            readCustomCharacteristic(ble, deviceId);
          } else {
            processCapturedData(mTransferBuffer);
            updateProgress(100); // Completato
          }
        } else if (mCurrentCommand == PK_COMMAND_VERIFY ||
            mCurrentCommand == PK_COMMAND_VERSION ||
            mCurrentCommand == PK_COMMAND_SET_POWER_OFF_2H ||
            mCurrentCommand == PK_COMMAND_SET_LEVEL_SECURITY_LOW ||
            mCurrentCommand == PK_COMMAND_GET_LEVEL_SECURITY) {
          processCapturedData(data);
        } else if (mCurrentCommand == PK_COMMAND_TEMPLATE) {
          processCapturedData(data);
        }
      }
    }
  }

  void processCapturedData(List<int> _data) async {
    Uint8List buffer = Uint8List.fromList(_data);

    var header = FMSHeader.fromBuffer(buffer);

    FMSData? data;

    if (!(header.pktCommand == PK_COMMAND_CAPTURE)) {
      data = FMSData.fromBytes(buffer);
    }
    if (header.pktCommand == PK_COMMAND_TEMPLATE) {
      switch (header.pktError) {
        case errNone:
          var fmsTemplate = FMSTemplateFile();

          fmsTemplate.write(data!.get(), data.dLength, 1);

          copyToBuffer(data.get(), data.dLength);
          updateProgress(0);
          addLog("Template Completed");
          completeRegisterFingerPrint(
              (OperationResult.success("Template Completed")));

          break;
        case errTimeout:
          addLog("Error Timeout");
          completeRegisterFingerPrint(OperationResult.error("Error Timeout"));
          break;
        default:
          completeRegisterFingerPrint(
              (OperationResult.success("Error Get Template")));
      }
    } else if (header.pktCommand == PK_COMMAND_VERIFY) {
      switch (header.pktError) {
        case errNone:
          addLog("Template  has been verified");
          completeVerifyFingerPrint(
              OperationResult.success("Template  has been verified"));

          break;
        case errVerifyFailed:
          addLog("Template is not verified.");
          completeVerifyFingerPrint(
              OperationResult.error("Template is not verified."));

        case errInvalidFormat:
          addLog("Format is invalid");
          completeVerifyFingerPrint(OperationResult.error("Format is invalid"));

          break;
        case errTimeout:
          addLog("Error Timeout");
          completeVerifyFingerPrint(OperationResult.error("Error Timeout"));
          break;
        default:
          addLog("Error Verify Template");
          completeVerifyFingerPrint(
              OperationResult.error("Error Verify Template"));
      }
    } else if (header.pktCommand == PK_COMMAND_VERSION) {
      switch (header.pktError) {
        case errNone:
          var status = (await parseResponse(buffer)).toString();
          addLog(status);
          completeVersionDevice(OperationResult.success(status));

          break;
        default:
          addLog("Error Version");
          completeVersionDevice(OperationResult.error("Error Version"));
      }
    } else if (header.pktCommand == PK_COMMAND_SET_POWER_OFF_2H) {
      switch (header.pktError) {
        case errNone:
          var status = (await parseResponse(buffer)).toString();
          addLog(status);
          completeSetPowerOff2H(OperationResult.success(status));

          break;
        default:
          addLog("Error Set Power Off 2h");
          completeSetPowerOff2H(
              OperationResult.error("Error Set Power Off 2h"));
      }
    } else if (header.pktCommand == PK_COMMAND_SET_LEVEL_SECURITY_LOW) {
      switch (header.pktError) {
        case errNone:
          var status = (await parseResponse(buffer)).toString();
          addLog(status);
          completeSetVerifySecurityLowLevel(OperationResult.success(status));

          break;
        default:
          addLog("Error Set Security Level");
          completeSetVerifySecurityLowLevel(
              OperationResult.error("Error Set Security Level"));
      }
    } else if (header.pktCommand == PK_COMMAND_GET_LEVEL_SECURITY) {
      switch (header.pktError) {
        case errNone:
          var status = (await parseResponse(buffer)).toString();
          addLog(status);
          completeGetSystemInfoSecurityLevel(OperationResult.success(
              "${status} - Result: ${header.pktParam2}"));

          break;
        default:
          addLog("Error Get Security Level");
          completeGetSystemInfoSecurityLevel(
              OperationResult.error("Error Get Security Level"));
      }
    }
  }

  void copyToBuffer(Uint8List data, int length) {
    mOneTemplateBuf.setRange(0, length, data);
    mOneTemplateSize = length;
  }

  Future readCustomCharacteristic(
      FlutterReactiveBle ble, String deviceId) async {
    try {
      final qualifiedCharacteristic = QualifiedCharacteristic(
        characteristicId: CHARACTERISTIC_READ_NOTIFY,
        serviceId: SERVICE_SECUGEN_SPP_OVER_BLE,
        deviceId: deviceId,
      );
      await ble.readCharacteristic(qualifiedCharacteristic);
    } catch (e) {
      addLog("Failed to read characteristic: $e");
    }
  }

  Future<OperationResult> getPowerOffTime2H(
      FlutterReactiveBle ble, String deviceId) async {
    final characteristicWrite = QualifiedCharacteristic(
        serviceId: SERVICE_SECUGEN_SPP_OVER_BLE,
        characteristicId: CHARACTERISTIC_WRITE,
        deviceId: deviceId);
    startNewSetPowerOffTime2HOperation();

    await ble.writeCharacteristicWithResponse(characteristicWrite,
        value: await setPowerOffTime2H());
    return _completerSetPowerOffTime2H!.future;
  }

  Future<OperationResult> getVerifySecurityLowLevel(
      FlutterReactiveBle ble, String deviceId) async {
    final characteristicWrite = QualifiedCharacteristic(
        serviceId: SERVICE_SECUGEN_SPP_OVER_BLE,
        characteristicId: CHARACTERISTIC_WRITE,
        deviceId: deviceId);
    startNewSetVerifySecurityLowLevelOperation();

    await ble.writeCharacteristicWithResponse(characteristicWrite,
        value: await setVerifySecurityLowLevel());
    return _completerSetVerifySecurityLowLevel!.future;
  }

  Future<OperationResult> getSystemVerifySecurityLowLevel(
      FlutterReactiveBle ble, String deviceId) async {
    final characteristicWrite = QualifiedCharacteristic(
        serviceId: SERVICE_SECUGEN_SPP_OVER_BLE,
        characteristicId: CHARACTERISTIC_WRITE,
        deviceId: deviceId);
    startNewGetSystemInfoSecurityLevelOperation();

    await ble.writeCharacteristicWithResponse(characteristicWrite,
        value: await getSystemInfoSecurityLevel());
    return _completerGetSystemInfoSecurityLevel!.future;
  }

  Future<OperationResult> getDeviceVersion(
      FlutterReactiveBle ble, String deviceId) async {
    final characteristicWrite = QualifiedCharacteristic(
        serviceId: SERVICE_SECUGEN_SPP_OVER_BLE,
        characteristicId: CHARACTERISTIC_WRITE,
        deviceId: deviceId);
    _completerVersionDevice = Completer<OperationResult>();
    startNewVersionDeviceOperation();

    await ble.writeCharacteristicWithResponse(characteristicWrite,
        value: await getVersion());
    return _completerVersionDevice!.future;
  }

  Future<OperationResult> instantVerifyFingerprint(
      FlutterReactiveBle ble, String deviceId) async {
    mTransferBuffer = mTransferBuffer;
    startNewVerifyFingerPrintOperation();

    final characteristicWrite = QualifiedCharacteristic(
        serviceId: SERVICE_SECUGEN_SPP_OVER_BLE,
        characteristicId: CHARACTERISTIC_WRITE,
        deviceId: deviceId);

    if (!mOneTemplateBuf.every((byte) => byte == 0)) {
      await ble.writeCharacteristicWithResponse(characteristicWrite,
          value: await instantVerifyExtraData(
              numberOfTemplate: 0,
              extraDataSize: mOneTemplateBuf.length, // mOneTemplateSize,
              extraData: mOneTemplateBuf)); // mOneTemplateBuf));
    } else {
      addLog("Template Saved not Found");
      completeVerifyFingerPrint(
          OperationResult.error("Template Saved not Found"));
    }
    return _completerVerifyFingerPrint!.future;
  }

  void dispose() {
    _logController.close();
    _statusStreamController.close();
    closeNfcSession();
    cancelPendingOperations();
  }

  //NFC
// Metodo per creare e serializzare il Template in JSON
  TemplateNFC createTemplate(String id, Uint8List template) {
    return TemplateNFC.fromUint8List(id, template);
  }

  Future<OperationResult> writeIntoNfc(String id) async {
    startNewWriteNfcOperation();

    if (mOneTemplateBuf.isNotEmpty) {
      try {
        // Notifica che siamo in attesa di una card NFC
        _sendStatusUpdateNfc(NfcOperationStatus.waitingForCard);
        // Avvia la scansione NFC
        NFCTag tag = await FlutterNfcKit.poll();

        if (tag.ndefWritable != null) {
          _sendStatusUpdateNfc(NfcOperationStatus.writing);

          TemplateNFC templateNfc = createTemplate(id, mOneTemplateBuf);

          String jsonString = jsonEncode(templateNfc.toJson());
          Uint8List jsonData = Uint8List.fromList(utf8.encode(jsonString));
          int dataSize = jsonData.length;
          addLog("dataSize: $dataSize");

          ndef.NDEFRecord record = ndef.NDEFRecord(
            tnf: ndef.TypeNameFormat.unknown,
            payload: jsonData,
          );
          await FlutterNfcKit.writeNDEFRecords([record]);

          addLog("Template scritto con successo sulla scheda NFC!");
          _sendStatusUpdateNfc(NfcOperationStatus.writeSuccess);

          completeWriteNfc(OperationResult.success(
              "Template scritto con successo sulla scheda NFC!"));
        } else {
          _sendStatusUpdateNfc(NfcOperationStatus.writeFailure);

          addLog("Il tag NFC non è scrivibile");
          completeWriteNfc(
              OperationResult.error("Il tag NFC non è scrivibile"));
        }
        return _completerWriteNfc!.future;
      } catch (e) {
        _sendStatusUpdateNfc(NfcOperationStatus.error);

        addLog("Errore durante la scrittura del template sulla scheda NFC: $e");
        completeWriteNfc(OperationResult.error(
            "Errore durante la scrittura del template sulla scheda NFC: $e"));
        return _completerWriteNfc!.future;
      } finally {
        // Termina la sessione NFC
        if (Platform.isIOS) {
          await FlutterNfcKit.finish();
        }
      }
    } else {
      addLog("Template not found");
      return _completerWriteNfc!.future;
    }
  }

  void closeNfcSession() async {
    try {
      await FlutterNfcKit.finish();
      addLog("Sessione NFC chiusa con successo");
    } catch (e) {
      addLog("Errore durante la chiusura della sessione NFC: $e");
    }
  }

  Future<OperationResult> readNfc() async {
    startNewReadNfcOperation();
    try {
      // Poll per trovare il tag NFC
      _sendStatusUpdateNfc(NfcOperationStatus.waitingForCard);
      NFCTag tag = await FlutterNfcKit.poll();
      if (Platform.isIOS) {
        await FlutterNfcKit.setIosAlertMessage("Sono in attesa di una Card Nfc...");
      }
      // Assicurati che il tag sia NDEF
      if (tag.ndefAvailable!) {
        _sendStatusUpdateNfc(NfcOperationStatus.reading);
        // Leggi i record NDEF dal tag
        List<ndef.NDEFRecord> records = await FlutterNfcKit.readNDEFRecords();
        if (records.isNotEmpty) {
          // Estrai e decodifica il payload
          List<int> payload = records.first.payload!;
          String payloadString = utf8.decode(payload);
          Map<String, dynamic> jsonData = jsonDecode(payloadString);
          // Estrai il campo 'template' (contenente Base64)
          String base64String = jsonData['template'];

          // Decodifica la stringa Base64 in Uint8List
          Uint8List template = base64Decode(base64String);
          String id = jsonData['id'];
          mOneTemplateBuf = template;

          // Crea un'istanza di TemplateNFC
          TemplateNFC templateNfc =
              TemplateNFC(id: id, templateBase64: base64String);
          addLog('NFC Data Success Id: $id  - template: $template');
          _sendStatusUpdateNfc(NfcOperationStatus.readSuccess);
          completeReadNfc(OperationResult.success(
              "NFC Read Data Success Id: $id  - template: $template",
              templateNfc));
        } else {
          addLog('No NDEF records found!');
          _sendStatusUpdateNfc(NfcOperationStatus.readFailure);

          completeReadNfc(OperationResult.error("No NDEF records found!"));
        }
      } else {
        addLog('NDEF not available on this tag!');
        _sendStatusUpdateNfc(NfcOperationStatus.readFailure);
        completeReadNfc(
            OperationResult.error("NDEF not available on this tag!"));
      }

      // Disconnessione NFC
      if (Platform.isIOS) {
        await FlutterNfcKit.finish();
      }
      //await FlutterNfcKit.finish(iosAlertMessage: "Finished!");
    } catch (e) {
      _sendStatusUpdateNfc(NfcOperationStatus.error);
      addLog('Error reading NFC tag: $e');
      if (Platform.isIOS) {
        await FlutterNfcKit.finish();
      }
      completeReadNfc(OperationResult.error("Error reading NFC tag: $e"));
    }
    return _completerReadNfc!.future;
  }
}

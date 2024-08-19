import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:secugen_ble_plugin/utils/fmsdata.dart';
import 'package:secugen_ble_plugin/utils/fmsheader.dart';
import 'package:secugen_ble_plugin/utils/fmstemplatefile.dart';
import 'secugen_ble_plugin_platform_interface.dart';

typedef DataCallback = void Function(String result);

class SecugenBlePlugin {
  Uint8List mOneTemplateBuf = Uint8List(400);
  int mOneTemplateSize = 0;
  int mBytesRead = 0;
  int mRemainingSize = 0;
  int mCurrentCommand = 0;
  static const int errNone = 0x00; // Nomrale Operazione
  static const int errVerifyFailed =
      0x04; // Errore di verifica dell'impronta digitale
  static const int errInvalidFormat = 0x30; //  Record format is invalid
  final StreamController<String> _logController =
      StreamController<String>.broadcast();
  Stream<String> get logStream => _logController.stream;
  ValueNotifier<int> progressNotifier = ValueNotifier<int>(0);
  DataCallback? onDataProcessed;

  static const int PACKET_HEADER_SIZE = 12;
  static const int IMG_WIDTH_MAX = 300;
  static const int PK_COMMAND_CAPTURE = 67;
  static const int PK_COMMAND_VERIFY = 208;
  static const int PK_COMMAND_VERSION = 5;
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

  Future<void> getFingerPrintTemplate(
      FlutterReactiveBle ble, String deviceId) async {
    mTransferBuffer =
        List<int>.filled(PACKET_HEADER_SIZE + IMG_SIZE_MAX + 1, 0);

    final characteristicWrite = QualifiedCharacteristic(
        serviceId: SERVICE_SECUGEN_SPP_OVER_BLE,
        characteristicId: CHARACTERISTIC_WRITE,
        deviceId: deviceId);

    await ble.writeCharacteristicWithResponse(characteristicWrite,
        value: await getTemplate());
  }

  void updateProgress(int progress) {
    progressNotifier.value = progress;
  }

  void addLog(String message) {
    _logController.add(message);
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
      print("Error enabling notifications: $e");
    }
  }

  void processCharacteristicData(FlutterReactiveBle ble, List<int> data,
      Uuid characteristicId, String deviceId) async {
    if (characteristicId == CHARACTERISTIC_READ_NOTIFY) {
      if (data.isNotEmpty &&
          data.length == PACKET_HEADER_SIZE &&
          data[0] == 0x4E) {
        print("Detected Notify message, try read data");
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
          print("mRemainingSize:  $mRemainingSize");
          print('mBytesRead: $mBytesRead');
          print('data.length: ${data.length}');
          print('mTransferBuffer length: ${mTransferBuffer.length}');
          print((mBytesRead * 100) ~/ (mRemainingSize + mBytesRead));

          if (mRemainingSize > 0) {
            updateProgress(
                ((mBytesRead * 100) ~/ (mRemainingSize + mBytesRead)));

            readCustomCharacteristic(ble, deviceId);
          } else {
            processCapturedData(mTransferBuffer);
            updateProgress(100); // Completato
          }
        } else if (mCurrentCommand == PK_COMMAND_VERIFY ||
            mCurrentCommand == PK_COMMAND_VERSION) {
          processCapturedData(data);
        }
      }
    }
  }

  void processCapturedData(List<int> _data) async {
    print("processCapturedData");

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
          addLog("Template Completed");
          if (onDataProcessed != null) {
            onDataProcessed!("Template Completed");
          }
          break;
        default:
          print("Error Get Template");
          if (onDataProcessed != null) {
            onDataProcessed!("Error Get Template");
          }
      }
    } else if (header.pktCommand == PK_COMMAND_VERIFY) {
      switch (header.pktError) {
        case errNone:
          print("Template  has been verified");

          addLog("Template  has been verified");
          if (onDataProcessed != null) {
            onDataProcessed!("Template  has been verified");
          }
          break;
        case errVerifyFailed:
          print("Template is not verified.");
          addLog("Template is not verified.");
          if (onDataProcessed != null) {
            onDataProcessed!("Template is not verified.");
          }
        case errInvalidFormat:
          print("Format is invalid");
          addLog("Format is invalid");
          if (onDataProcessed != null) {
            onDataProcessed!("Format is invalid");
          }
          break;
        default:
          print("Error Verify Template");
          addLog("Error Verify Template");
          if (onDataProcessed != null) {
            onDataProcessed!("Error Verify Template");
          }
      }
    } else if (header.pktCommand == PK_COMMAND_VERSION) {
      switch (header.pktError) {
        case errNone:
          var status = (await parseResponse(buffer)).toString();
          print(status);
          addLog(status);
          if (onDataProcessed != null) {
            onDataProcessed!(status);
          }
          break;
        default:
          print("Error Version");
          addLog("Error Version");
          if (onDataProcessed != null) {
            onDataProcessed!("Error Version");
          }
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
      print("Failed to read characteristic: $e");
    }
  }

  Future<void> getDeviceVersion(FlutterReactiveBle ble, String deviceId) async {
    final characteristicWrite = QualifiedCharacteristic(
        serviceId: SERVICE_SECUGEN_SPP_OVER_BLE,
        characteristicId: CHARACTERISTIC_WRITE,
        deviceId: deviceId);

    await ble.writeCharacteristicWithResponse(characteristicWrite,
        value: await getVersion());
  }

  Future<void> instantVerifyFingerprint(
      FlutterReactiveBle ble, String deviceId) async {
    mTransferBuffer = mTransferBuffer;

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
      print("Template Saved not Found");
      addLog("Template Saved not Found");
      if (onDataProcessed != null) {
        onDataProcessed!("Template Saved not Found");
      }
    }
  }

  void dispose() {
    _logController.close();
  }
}

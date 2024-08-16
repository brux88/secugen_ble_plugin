import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:functional_data/functional_data.dart';
import 'package:provider/provider.dart';
import 'package:secugen_ble_plugin/secugen_ble_plugin.dart';
import 'package:secugen_ble_plugin/utils/fmsheader.dart';
import 'package:secugen_ble_plugin/utils/fmsdata.dart';
import 'package:secugen_ble_plugin/utils/fmstemplatefile.dart';
import 'package:secugen_ble_plugin_example/ble/ble_device_connector.dart';
import 'package:secugen_ble_plugin_example/ble/ble_device_interactor.dart';

import 'characteristic_interaction_dialog.dart';

part 'device_interaction_tab.g.dart';

// ignore_for_file: annotate_overrides

class DeviceInteractionTab extends StatelessWidget {
  const DeviceInteractionTab({
    required this.device,
    Key? key,
  }) : super(key: key);

  final DiscoveredDevice device;

  @override
  Widget build(BuildContext context) =>
      Consumer3<BleDeviceConnector, ConnectionStateUpdate, BleDeviceInteractor>(
        builder: (_, deviceConnector, connectionStateUpdate, serviceDiscoverer,
                __) =>
            _DeviceInteractionTab(
          viewModel: DeviceInteractionViewModel(
            deviceId: device.id,
            connectableStatus: device.connectable,
            connectionStatus: connectionStateUpdate.connectionState,
            deviceConnector: deviceConnector,
            discoverServices: () =>
                serviceDiscoverer.discoverServices(device.id),
            readRssi: () => serviceDiscoverer.readRssi(device.id),
          ),
        ),
      );
}

@immutable
@FunctionalData()
class DeviceInteractionViewModel extends $DeviceInteractionViewModel {
  const DeviceInteractionViewModel({
    required this.deviceId,
    required this.connectableStatus,
    required this.connectionStatus,
    required this.deviceConnector,
    required this.discoverServices,
    required this.readRssi,
  });

  final String deviceId;
  final Connectable connectableStatus;
  final DeviceConnectionState connectionStatus;
  final BleDeviceConnector deviceConnector;
  final Future<int> Function() readRssi;

  @CustomEquality(Ignore())
  final Future<List<Service>> Function() discoverServices;

  bool get deviceConnected =>
      connectionStatus == DeviceConnectionState.connected;

  Future<void> connect() async {
    deviceConnector.connect(deviceId);
  }

  void disconnect() {
    deviceConnector.disconnect(deviceId);
  }
}

class _DeviceInteractionTab extends StatefulWidget {
  const _DeviceInteractionTab({
    required this.viewModel,
    Key? key,
  }) : super(key: key);

  final DeviceInteractionViewModel viewModel;

  @override
  _DeviceInteractionTabState createState() => _DeviceInteractionTabState();
}

class _DeviceInteractionTabState extends State<_DeviceInteractionTab> {
  late List<Service> discoveredServices;
  final _secugenBlePlugin = SecugenBlePlugin();
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  static const int PACKET_HEADER_SIZE = 12;
  static const int IMG_WIDTH_MAX = 300;
  static const int PK_COMMAND_CAPTURE = 67;
  static const int PK_COMMAND_VERIFY = 208;
  static const int PK_COMMAND_VERSION = 5;
  static const int PK_COMMAND_TEMPLATE = 64;
  static const int IMG_HEIGHT_MAX = 400;
  static const int IMG_SIZE_MAX = (IMG_WIDTH_MAX * IMG_HEIGHT_MAX);
  static const int errNone = 0x00; // Nomrale Operazione
  static const int errVerifyFailed =
      0x04; // Errore di verifica dell'impronta digitale
  static const int errInvalidFormat = 0x30; //  Record format is invalid

  static Uuid CHARACTERISTIC_READ_NOTIFY =
      Uuid.parse("00002bb1-0000-1000-8000-00805f9b34fb");
  static Uuid CHARACTERISTIC_WRITE =
      Uuid.parse("00002bb2-0000-1000-8000-00805f9b34fb");
  static Uuid SERVICE_SECUGEN_SPP_OVER_BLE =
      Uuid.parse("0000fda0-0000-1000-8000-00805f9b34fb");
  String _status = "";
  List<int> mTransferBuffer =
      List<int>.filled(PACKET_HEADER_SIZE + IMG_SIZE_MAX + 1, 0);
  int mBytesRead = 0;
  int mRemainingSize = 0;
  int mCurrentCommand = 0;
  @override
  void initState() {
    discoveredServices = [];
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void processCharacteristicData(
      List<int> data, Uuid characteristicId, String deviceId) async {
    if (characteristicId == CHARACTERISTIC_READ_NOTIFY) {
      if (data.isNotEmpty &&
          data.length == PACKET_HEADER_SIZE &&
          data[0] == 0x4E) {
        print("Detected Notify message, try read data");
        readCustomCharacteristic(deviceId);
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
            readCustomCharacteristic(deviceId);
          } else {
            processCapturedData(mTransferBuffer);
          }
        } else if (mCurrentCommand == PK_COMMAND_VERIFY ||
            mCurrentCommand == PK_COMMAND_VERSION) {
          processCapturedData(data);
        }
      }
    }
  }

  Uint8List mOneTemplateBuf = Uint8List(1024);
  int mOneTemplateSize = 0;
  void copyToBuffer(Uint8List data, int length) {
    mOneTemplateBuf.setRange(0, length, data);
    mOneTemplateSize = length;
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
          setState(() {
            _status = "Template saved with success";
          });
          break;
        default:
          print("Error Get Template");
          setState(() {
            _status = "Error Get Template";
          });
      }
    } else if (header.pktCommand == PK_COMMAND_VERIFY) {
      switch (header.pktError) {
        case errNone:
          print("Template  has been verified");
          setState(() {
            _status = "Template  has been verified";
          });
          break;
        case errVerifyFailed:
          print("Template is not verified.");
          setState(() {
            _status = "Template is not verified.";
          });
        case errInvalidFormat:
          print("Format is invalid");
          setState(() {
            _status = "Format is invalid";
          });
          break;
        default:
          print("Error Verify Template");
          setState(() {
            _status = "Error Verify Template";
          });
      }
    } else if (header.pktCommand == PK_COMMAND_VERSION) {
      switch (header.pktError) {
        case errNone:
          _status = (await _secugenBlePlugin.parseResponse(buffer)).toString();
          setState(() {});
          break;
        default:
          print("Error Version");
          setState(() {
            _status = "Error get Version";
          });
      }
    }
  }

  Future readCustomCharacteristic(String deviceId) async {
    try {
      final qualifiedCharacteristic = QualifiedCharacteristic(
        characteristicId: CHARACTERISTIC_READ_NOTIFY,
        serviceId: SERVICE_SECUGEN_SPP_OVER_BLE,
        deviceId: deviceId,
      );
      await _ble.readCharacteristic(qualifiedCharacteristic);
    } catch (e) {
      print("Failed to read characteristic: $e");
    }
  }

  Future<void> discoverServices() async {
    final result = await widget.viewModel.discoverServices();
    setState(() {
      discoveredServices = result;
    });
  }

  Future<void> enableNotifications(
      QualifiedCharacteristic characteristic) async {
    try {
      _ble.subscribeToCharacteristic(characteristic).listen((data) {
        processCharacteristicData(
            data, characteristic.characteristicId, characteristic.deviceId);
      });
    } catch (e) {
      print("Error enabling notifications: $e");
    }
  }

  Future<void> instantVerifyExtraData() async {
    mTransferBuffer =
        List<int>.filled(PACKET_HEADER_SIZE + IMG_SIZE_MAX + 1, 0);

    final characteristicWrite = QualifiedCharacteristic(
        serviceId: SERVICE_SECUGEN_SPP_OVER_BLE,
        characteristicId: CHARACTERISTIC_WRITE,
        deviceId: widget.viewModel.deviceId);

    var templateSaved = await FMSTemplateFile().read(1);

    if (templateSaved != null) {
      await _ble.writeCharacteristicWithResponse(characteristicWrite,
          value: await _secugenBlePlugin.instantVerifyExtraData(
              numberOfTemplate: 0,
              extraDataSize: templateSaved.length, // mOneTemplateSize,
              extraData: templateSaved)); // mOneTemplateBuf));
    } else {
      print("Template Saved not Found");
      throw ("Template Saved not Found");
    }
  }

  Future<void> getTemplate() async {
    mTransferBuffer =
        List<int>.filled(PACKET_HEADER_SIZE + IMG_SIZE_MAX + 1, 0);

    final characteristicWrite = QualifiedCharacteristic(
        serviceId: SERVICE_SECUGEN_SPP_OVER_BLE,
        characteristicId: CHARACTERISTIC_WRITE,
        deviceId: widget.viewModel.deviceId);

    await _ble.writeCharacteristicWithResponse(characteristicWrite,
        value: await _secugenBlePlugin.getTemplate());
  }

  Future<void> getVersion() async {
    final characteristicWrite = QualifiedCharacteristic(
        serviceId: SERVICE_SECUGEN_SPP_OVER_BLE,
        characteristicId: CHARACTERISTIC_WRITE,
        deviceId: widget.viewModel.deviceId);

    await _ble.writeCharacteristicWithResponse(characteristicWrite,
        value: await _secugenBlePlugin.getVersion());
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate.fixed(
              [
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                      top: 8.0, bottom: 16.0, start: 16.0),
                  child: Text(
                    "ID: ${widget.viewModel.deviceId}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16.0),
                  child: Text(
                    "Connectable: ${widget.viewModel.connectableStatus}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16.0),
                  child: Text(
                    "Connection: ${widget.viewModel.connectionStatus}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16.0),
                  child: Text(
                    "Status: $_status  ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: () async {
                          if (!widget.viewModel.deviceConnected) {
                            await widget.viewModel.connect();
                            final characteristicRead = QualifiedCharacteristic(
                                serviceId: SERVICE_SECUGEN_SPP_OVER_BLE,
                                characteristicId: CHARACTERISTIC_READ_NOTIFY,
                                deviceId: widget.viewModel.deviceId);
                            await enableNotifications(characteristicRead);
                          }
                        },
                        child: const Text("Connect"),
                      ),
                      ElevatedButton(
                        onPressed: widget.viewModel.deviceConnected
                            ? widget.viewModel.disconnect
                            : null,
                        child: const Text("Disconnect"),
                      ),
                      ElevatedButton(
                        onPressed: widget.viewModel.deviceConnected
                            ? discoverServices
                            : null,
                        child: const Text("Discover Services"),
                      ),
                      ElevatedButton(
                        onPressed: widget.viewModel.deviceConnected
                            ? getVersion
                            : null,
                        child: const Text("Get Version"),
                      ),
                      ElevatedButton(
                        onPressed: widget.viewModel.deviceConnected
                            ? getTemplate
                            : null,
                        child: const Text("Get Template"),
                      ),
                      ElevatedButton(
                        onPressed: widget.viewModel.deviceConnected
                            ? instantVerifyExtraData
                            : null,
                        child: const Text("Instant Verify"),
                      ),
                    ],
                  ),
                ),
                if (widget.viewModel.deviceConnected)
                  _ServiceDiscoveryList(
                    deviceId: widget.viewModel.deviceId,
                    discoveredServices: discoveredServices,
                  ),
              ],
            ),
          ),
        ],
      );
}

class _ServiceDiscoveryList extends StatefulWidget {
  const _ServiceDiscoveryList({
    required this.deviceId,
    required this.discoveredServices,
    Key? key,
  }) : super(key: key);

  final String deviceId;
  final List<Service> discoveredServices;

  @override
  _ServiceDiscoveryListState createState() => _ServiceDiscoveryListState();
}

class _ServiceDiscoveryListState extends State<_ServiceDiscoveryList> {
  late final List<int> _expandedItems;

  @override
  void initState() {
    _expandedItems = [];
    super.initState();
  }

  String _characteristicSummary(Characteristic c) {
    final props = <String>[];
    if (c.isReadable) {
      props.add("read");
    }
    if (c.isWritableWithoutResponse) {
      props.add("write without response");
    }
    if (c.isWritableWithResponse) {
      props.add("write with response");
    }
    if (c.isNotifiable) {
      props.add("notify");
    }
    if (c.isIndicatable) {
      props.add("indicate");
    }

    return props.join("\n");
  }

  Widget _characteristicTile(Characteristic characteristic) => ListTile(
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) =>
              CharacteristicInteractionDialog(characteristic: characteristic),
        ),
        title: Text(
          '${characteristic.id}\n(${_characteristicSummary(characteristic)})',
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
      );

  List<ExpansionPanel> buildPanels() {
    final panels = <ExpansionPanel>[];

    widget.discoveredServices.asMap().forEach(
          (index, service) => panels.add(
            ExpansionPanel(
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsetsDirectional.only(start: 16.0),
                    child: Text(
                      'Characteristics',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: service.characteristics
                        .map(_characteristicTile)
                        .toList(),
                  ),
                ],
              ),
              headerBuilder: (context, isExpanded) => ListTile(
                title: Text(
                  '${service.id}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              isExpanded: _expandedItems.contains(index),
            ),
          ),
        );

    return panels;
  }

  @override
  Widget build(BuildContext context) => widget.discoveredServices.isEmpty
      ? const SizedBox()
      : SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              top: 20.0,
              start: 20.0,
              end: 20.0,
            ),
            child: ExpansionPanelList(
              expansionCallback: (int index, bool isExpanded) {
                setState(() {
                  if (isExpanded) {
                    _expandedItems.remove(index);
                  } else {
                    _expandedItems.add(index);
                  }
                });
              },
              children: buildPanels(),
            ),
          ),
        );
}

class Message {
  final int what;
  final List<int> obj;
  final int arg1;
  final int arg2;

  Message(this.what, this.obj, {this.arg1 = 0, this.arg2 = 0});
}

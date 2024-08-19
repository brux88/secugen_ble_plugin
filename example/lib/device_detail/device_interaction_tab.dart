import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
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
import 'package:ndef/ndef.dart' as ndef;
import 'package:uuid/uuid.dart' as guidpack;

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

  String _status = "";
  List<int> mTransferBuffer = [];

  @override
  void initState() {
    discoveredServices = [];
    super.initState();
    mTransferBuffer = _secugenBlePlugin.mTransferBuffer;
    _secugenBlePlugin.onDataProcessed = (result) {
      setState(() {
        _status = result;
      });
    };
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> discoverServices() async {
    final result = await widget.viewModel.discoverServices();
    setState(() {
      discoveredServices = result;
    });
  }

  Map<String, dynamic> createJsonTemplate(Uint8List template) {
    String guid = guidpack.Uuid().v4(); // Genera un GUID

    // Crea una mappa JSON con il GUID e il template
    Map<String, dynamic> jsonTemplate = {
      'id': guid,
      'template': base64Encode(
          template), // Codifica il template in base64 per salvarlo come stringa
    };

    return jsonTemplate;
  }

  Future<void> _readNfc() async {
    try {
      // Poll per trovare il tag NFC
      NFCTag tag = await FlutterNfcKit.poll();

      // Assicurati che il tag sia NDEF
      if (tag.ndefAvailable!) {
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
          _secugenBlePlugin.mOneTemplateBuf = template;
          print('NFC Data Id: $id  - template: template');
          setState(() {
            _status = 'NFC Data: $jsonData';
          });
        } else {
          print('No NDEF records found!');

          setState(() {
            _status = 'No NDEF records found!';
          });
        }
      } else {
        print('NDEF not available on this tag!');
        setState(() {
          _status = 'NDEF not available on this tag!';
        });
      }

      // Disconnessione NFC
      await FlutterNfcKit.finish(iosAlertMessage: "Finished!");
    } catch (e) {
      print('Error reading NFC tag: $e');
      setState(() {
        _status = 'Error reading NFC tag: $e';
      });
    }
  }

  Future<void> writeIntoNfc() async {
    if (_secugenBlePlugin.mOneTemplateBuf.isNotEmpty) {
      try {
        // Avvia la scansione NFC
        NFCTag tag = await FlutterNfcKit.poll();

        // Assicurati che il tag sia supportato
        if (tag.ndefWritable != null) {
          // Converti la stringa JSON in Uint8List
          // Converti il JSON in stringa
          String jsonString =
              jsonEncode(createJsonTemplate(_secugenBlePlugin.mOneTemplateBuf));
          Uint8List jsonData = Uint8List.fromList(utf8.encode(jsonString));
          int dataSize = jsonData.length;
          print("dataSize: $dataSize");

          // Crea un NDEF record con il tuo template
          ndef.NDEFRecord record = ndef.NDEFRecord(
            tnf: ndef.TypeNameFormat.unknown,
            payload: jsonData,
          );
          // Scrivi il record sul tag NFC
          await FlutterNfcKit.writeNDEFRecords([record]);

          /* // Dividi i dati in blocchi e scrivi ciascun blocco sulla scheda NFC
          for (int i = 0; i < jsonData.length; i += 16) {
            List<int> blocco =
                jsonData.sublist(i, min(i + 16, jsonData.length));
            // Prepara il comando di scrittura
            String writeCommand =
                'WRITE_COMMAND${blocco.map((e) => e.toRadixString(16).padLeft(2, '0')).join()}';
            // Scrivi il blocco sulla scheda NFC
            await FlutterNfcKit.transceive(writeCommand);
          }*/

          // Scrivi i dati sulla scheda NFC
          //  await FlutterNfcKit.transceive(jsonData);

          print("Template scritto con successo sulla scheda NFC!");
          setState(() {
            _status = "Template scritto con successo sulla scheda NFC!";
          });
        } else {
          print("Il tag NFC non è scrivibile");
          setState(() {
            _status = "Il tag NFC non è scrivibile";
          });
        }
      } catch (e) {
        print("Errore durante la scrittura del template sulla scheda NFC: $e");
        setState(() {
          _status =
              "Errore durante la scrittura del template sulla scheda NFC: $e";
        });
      } finally {
        // Termina la sessione NFC
        await FlutterNfcKit.finish();
      }
    } else {
      showErrorSnackbar(context, "Template not found");
    }
  }

  void showErrorSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red, // colore di sfondo del messaggio di errore
      duration:
          Duration(seconds: 3), // durata della visualizzazione del messaggio
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
                const SizedBox(
                  height: 10,
                ),
                ValueListenableBuilder<int>(
                  valueListenable: _secugenBlePlugin.progressNotifier,
                  builder: (context, progress, child) {
                    return LinearProgressIndicator(value: progress / 100.0);
                  },
                ),
                const SizedBox(
                  height: 10,
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
                            await _secugenBlePlugin.enableNotifications(
                                _ble, widget.viewModel.deviceId);
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
                        onPressed: () async {
                          if (widget.viewModel.deviceConnected) {
                            await _secugenBlePlugin.getDeviceVersion(
                                _ble, widget.viewModel.deviceId);
                          }
                        },
                        child: const Text("Get Version"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (widget.viewModel.deviceConnected) {
                            await _secugenBlePlugin.getFingerPrintTemplate(
                                _ble, widget.viewModel.deviceId);
                          }
                        },
                        child: const Text("Get Template"),
                      ),
                      ElevatedButton(
                        onPressed: widget.viewModel.deviceConnected
                            ? writeIntoNfc
                            : null,
                        child: const Text("Write Template Nfc"),
                      ),
                      ElevatedButton(
                        onPressed:
                            widget.viewModel.deviceConnected ? _readNfc : null,
                        child: const Text("Read Template Nfc"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (widget.viewModel.deviceConnected) {
                            await _secugenBlePlugin.instantVerifyFingerprint(
                                _ble, widget.viewModel.deviceId);
                          }
                        },
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

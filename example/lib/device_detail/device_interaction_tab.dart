import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:functional_data/functional_data.dart';
import 'package:provider/provider.dart';
import 'package:secugen_ble_plugin/secugen_ble_plugin.dart';
import 'package:secugen_ble_plugin/utils/enum.dart';

import 'package:secugen_ble_plugin_example/ble/ble_device_connector.dart';
import 'package:secugen_ble_plugin_example/ble/ble_device_interactor.dart';

import 'characteristic_interaction_dialog.dart';
import 'package:uuid/uuid.dart' as guid;

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
  late SecugenBlePlugin _secugenBlePlugin;
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<NfcOperationStatus>? _statusSubscription;

  String _status = "";
  List<int> mTransferBuffer = [];

  @override
  void initState() {
    discoveredServices = [];
    super.initState();

    _secugenBlePlugin = SecugenBlePlugin();

// Ascolta gli aggiornamenti dello stato
    /*_secugenBlePlugin.statusStream.listen((status) {
      // Aggiorna lo stato dell'interfaccia utente
      setState(() {
        _handleStatusUpdate(status);
      });
    });*/
    _startListeningToStatusUpdates();

    mTransferBuffer = _secugenBlePlugin.mTransferBuffer;
  }

  void _startListeningToStatusUpdates() {
    // Cancella la vecchia subscription se esiste
    _statusSubscription?.cancel();

    // Avvia una nuova subscription allo stream
    _statusSubscription = _secugenBlePlugin.statusStream.listen((status) {
      setState(() {
        _handleStatusUpdate(status);
      });
    });
  }

  void _handleStatusUpdate(NfcOperationStatus status) {
    switch (status) {
      case NfcOperationStatus.waitingForCard:
        print("In attesa di una card NFC");
        setState(() {
          _status = "In attesa di una card NFC";
        });
        break;
      case NfcOperationStatus.writing:
        print("In fase di scrittura");
        setState(() {
          _status = "In fase di scrittura";
        });
        break;
      case NfcOperationStatus.writeSuccess:
        print("Scrittura completata con successo");
        setState(() {
          _status = "Scrittura completata con successo";
        });
        break;
      case NfcOperationStatus.writeFailure:
        print("Scrittura fallita");
        setState(() {
          _status = "Scrittura fallita";
        });
        break;
      case NfcOperationStatus.error:
        print("Errore durante l'operazione");
        setState(() {
          _status = "Errore durante l'operazione";
        });
        break;
      default:
        setState(() {
          _status = "In attesa di una card NFC";
        });
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  Future<void> discoverServices() async {
    final result = await widget.viewModel.discoverServices();
    setState(() {
      discoveredServices = result;
    });
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
                            var result =
                                await _secugenBlePlugin.getDeviceVersion(
                                    _ble, widget.viewModel.deviceId);
                            print(result);
                            setState(() {
                              _status = "${result.message} ";
                            });
                          }
                        },
                        child: const Text("Get Version"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (widget.viewModel.deviceConnected) {
                            var result =
                                await _secugenBlePlugin.getFingerPrintTemplate(
                                    _ble, widget.viewModel.deviceId);
                            setState(() {
                              _status =
                                  "${result.message} - ${DateTime.timestamp().toIso8601String()}";
                            });
                          }
                        },
                        child: const Text("Get Template"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          showFingerPrintBottomSheet(context);
                        },
                        child: const Text("Open BottomSheet Register Fp"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (widget.viewModel.deviceConnected) {
                            var idFake = guid.Uuid().v4();
                            var result =
                                await _secugenBlePlugin.writeIntoNfc(idFake);
                            setState(() {
                              _status = result.message;
                            });
                          }
                        },
                        child: const Text("Write Template Nfc"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (widget.viewModel.deviceConnected) {
                            var result = await _secugenBlePlugin.readNfc();
                            setState(() {
                              _status = result.message;
                            });
                          }
                        },
                        child: const Text("Read Template Nfc"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (widget.viewModel.deviceConnected) {
                            var result = await _secugenBlePlugin
                                .instantVerifyFingerprint(
                                    _ble, widget.viewModel.deviceId);
                            setState(() {
                              _status = result.message;
                            });
                          }
                        },
                        child: const Text("Instant Verify"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (widget.viewModel.deviceConnected) {
                            var result =
                                await _secugenBlePlugin.getPowerOffTime2H(
                                    _ble, widget.viewModel.deviceId);
                            setState(() {
                              _status = result.message;
                            });
                          }
                        },
                        child: const Text("Set Power off Time 2h"),
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

  void showFingerPrintBottomSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        final _secugenBlePlugin2 = SecugenBlePlugin();

        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () async {
                  if (widget.viewModel.deviceConnected) {
                    var idFake = guid.Uuid().v4();
                    var result = await _secugenBlePlugin.writeIntoNfc(idFake);
                    setState(() {
                      _status = result.message;
                    });
                  }
                },
                child: const Text("Write Template Nfc"),
              ),
              ElevatedButton(
                onPressed: () async {
                  {
                    if (widget.viewModel.deviceConnected) {
                      await _secugenBlePlugin2.enableNotifications(
                          _ble, widget.viewModel.deviceId);
                      var result =
                          await _secugenBlePlugin2.getFingerPrintTemplate(
                              _ble, widget.viewModel.deviceId);
                      setState(() {
                        _status =
                            "${result.message} - ${DateTime.timestamp().toIso8601String()}";
                      });
                    }
                  }
                },
                child: const Text("Get Template"),
              ),
            ],
          ),
        );
      },
    );
    _secugenBlePlugin.dispose();
    _startListeningToStatusUpdates();
  }
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

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:secugen_ble_plugin/secugen_ble_plugin.dart';
import 'package:secugen_ble_plugin_example/ble/ble_device_connector.dart';
import 'package:secugen_ble_plugin_example/ble/ble_device_interactor.dart';
import 'package:secugen_ble_plugin_example/ble/ble_logger.dart';
import 'package:secugen_ble_plugin_example/ble/ble_scanner.dart';
import 'package:secugen_ble_plugin_example/ble/ble_status_monitor.dart';
import 'package:secugen_ble_plugin_example/ble_status_screen.dart';
import 'package:secugen_ble_plugin_example/device_list.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final _ble = FlutterReactiveBle();
  final _bleLogger = BleLogger(ble: _ble);
  final _scanner = BleScanner(ble: _ble, logMessage: _bleLogger.addToLog);
  final _monitor = BleStatusMonitor(_ble);
  final _connector = BleDeviceConnector(
    ble: _ble,
    logMessage: _bleLogger.addToLog,
  );
  final _serviceDiscoverer = BleDeviceInteractor(
    bleDiscoverServices: (deviceId) async {
      await _ble.discoverAllServices(deviceId);
      return _ble.getDiscoveredServices(deviceId);
    },
    logMessage: _bleLogger.addToLog,
    readRssi: _ble.readRssi,
  );
  runApp(MultiProvider(providers: [
    Provider.value(value: _scanner),
    Provider.value(value: _monitor),
    Provider.value(value: _connector),
    Provider.value(value: _serviceDiscoverer),
    Provider.value(value: _bleLogger),
    StreamProvider<BleScannerState?>(
      create: (_) => _scanner.state,
      initialData: const BleScannerState(
        discoveredDevices: [],
        scanIsInProgress: false,
      ),
    ),
    StreamProvider<BleStatus?>(
      create: (_) => _monitor.state,
      initialData: BleStatus.unknown,
    ),
    StreamProvider<ConnectionStateUpdate>(
      create: (_) => _connector.state,
      initialData: const ConnectionStateUpdate(
        deviceId: 'Unknown device',
        connectionState: DeviceConnectionState.disconnected,
        failure: null,
      ),
    ),
  ], child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //String _platformVersion = 'Unknown';
  final _secugenBlePlugin = SecugenBlePlugin();

  @override
  void initState() {
    super.initState();
    // initPlatformState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /*Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion =
          await _secugenBlePlugin.getVersion() ?? 'Unknown  version';

      var testmakeRecordStart = await _secugenBlePlugin.makeRecordStart(6);
      var testmakeRecordCont = await _secugenBlePlugin.makeRecordCont(8);
      var testloadMatchtemplate =
          await _secugenBlePlugin.loadMatchTemplateWithExtraData(
              extraDataSize: 1, extraData: Uint8List(20));
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }*/
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.lightBlue,
      home: MainPage(),
    );
  }

  /* @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }*/
}

Future<void> requestBluetoothPermissions() async {
  if (await Permission.bluetoothScan.request().isGranted &&
      await Permission.bluetoothConnect.request().isGranted &&
      await Permission.locationWhenInUse.request().isGranted) {
    // I permessi sono stati concessi, puoi procedere
    print("Permessi concessi");
  } else {
    // I permessi sono stati negati
    print("Permessi negati");
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  void initState() {
    super.initState();
    requestBluetoothPermissions();
  }

  @override
  Widget build(BuildContext context) => Consumer<BleStatus?>(
        builder: (_, status, __) {
          if (status == BleStatus.ready) {
            return const DeviceListScreen();
          } else {
            return BleStatusScreen(status: status ?? BleStatus.unknown);
          }
        },
      );
}

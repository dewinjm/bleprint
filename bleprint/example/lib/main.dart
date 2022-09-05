// Copyright (c) 2022 Dewin J. Martinez
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:bleprint/bleprint.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Print Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late BluetoothManager bluetoothManager;

  @override
  void initState() {
    super.initState();
    bluetoothManager = BluetoothManager();
    _getBondedDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BLE Print Example')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _scanWidget(),
                StreamBuilder<List<BluetoothDevice>>(
                  stream: bluetoothManager.onScanResult,
                  initialData: const [],
                  builder: (_, snapshot) => Column(
                    children: snapshot.data!.map(_buildItem).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scanWidget() {
    return StreamBuilder<bool>(
      initialData: false,
      stream: bluetoothManager.isScanning,
      builder: (context, snapshot) {
        return (snapshot.data ?? false)
            ? Column(
                children: const [
                  Text('Wait bluetooth scan'),
                  SizedBox(height: 8),
                  CircularProgressIndicator(),
                ],
              )
            : Column(
                children: [
                  const Text('Please press scan button to start scanning'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _scanDevices,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: const [
                          Text('Scan'),
                        ],
                      ),
                    ),
                  ),
                ],
              );
      },
    );
  }

  Widget _buildItem(BluetoothDevice device) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 600,
      ),
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bluetooth),
                  const SizedBox(width: 8),
                  Text(device.name),
                ],
              ),
              const SizedBox(width: 16),
              _connectButton(device),
            ],
          ),
        ),
      ),
    );
  }

  Widget _connectButton(BluetoothDevice device) {
    return StreamBuilder<BluetoothDeviceState>(
      initialData: BluetoothDeviceState.disconnected,
      stream: device.stateListener,
      builder: (context, snapshot) {
        final isConnected = snapshot.data == BluetoothDeviceState.connected;
        final isLoading = snapshot.data == BluetoothDeviceState.connecting;

        return ElevatedButton(
          onPressed: () => isConnected ? _disconnect(device) : _connect(device),
          style: ElevatedButton.styleFrom(
            primary: isConnected ? Colors.red : Colors.blue,
          ),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Text(isConnected ? 'Disconnect' : 'Connect'),
        );
      },
    );
  }

  Future<void> _scanDevices() async {
    try {
      await bluetoothManager.scanDevices(duration: const Duration(seconds: 4));
    } catch (ex) {
      _showError(ex);
    }
  }

  Future<void> _getBondedDevices() async {
    try {
      await bluetoothManager.bondedDevices();
    } catch (ex) {
      _showError(ex);
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    try {
      await bluetoothManager.connect(
        device: device,
        duration: const Duration(seconds: 10),
      );
    } catch (ex) {
      _showError(ex);
    }
  }

  Future<void> _disconnect(BluetoothDevice device) async {
    try {
      await bluetoothManager.disconnect(device: device);
    } catch (ex) {
      _showError(ex);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).primaryColor,
        content: Text('$error'),
      ),
    );
  }
}

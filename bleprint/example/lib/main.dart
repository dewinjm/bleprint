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
  bool _isScanning = false;
  List<BluetoothDevice> _devices = <BluetoothDevice>[];

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
                Column(
                  children: _devices.map(_buildItem).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scanWidget() {
    return _isScanning
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
    final isConnected = device.isConnected ?? false;

    return ElevatedButton(
      onPressed: () => isConnected ? _disconnect(device) : _connect(device),
      style: ElevatedButton.styleFrom(
        primary: isConnected ? Colors.red : Colors.blue,
      ),
      child: Text(isConnected ? 'Disconnect' : 'Connect'),
    );
  }

  void _scanDevices() {
    setState(() {
      _isScanning = true;
      _devices = <BluetoothDevice>[];
    });

    bluetoothManager.scanDevices(duration: const Duration(seconds: 4)).listen(
      (devices) {
        setState(() {
          _devices = devices;
          _isScanning = false;
        });
      },
    ).onError((Object error, _) {
      setState(() {
        _isScanning = false;
      });

      _showError(error);
    });
  }

  Future<void> _getBondedDevices() async {
    setState(() {
      _isScanning = true;
      _devices = <BluetoothDevice>[];
    });

    try {
      final result = await bluetoothManager.bondedDevices();
      _devices.addAll(result);
    } catch (ex) {
      _showError(ex);
    }

    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() {
      _isScanning = true;
    });

    try {
      final result = await bluetoothManager.connect(
        device: device,
        duration: const Duration(seconds: 5),
      );

      setState(() {
        final index = _devices.indexWhere((e) => e.address == device.address);
        _devices[index] = device.copyWith(isConnected: result);
      });
    } catch (ex) {
      _showError(ex);
    }

    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _disconnect(BluetoothDevice device) async {
    setState(() {
      _isScanning = true;
    });

    try {
      final result = await bluetoothManager.disconnect(device: device);

      setState(() {
        final index = _devices.indexWhere((e) => e.address == device.address);
        _devices[index] = device.copyWith(isConnected: result);
      });
    } catch (ex) {
      _showError(ex);
    }

    setState(() {
      _isScanning = false;
    });
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

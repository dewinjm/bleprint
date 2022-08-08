// Copyright (c) 2022, Very Good Ventures
// https://verygood.ventures
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

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
              ElevatedButton(onPressed: () {}, child: const Text('Connect')),
            ],
          ),
        ),
      ),
    );
  }

  void _scanDevices() {
    setState(() {
      _isScanning = true;
      _devices = <BluetoothDevice>[];
    });

    bluetoothManager.scanDevices(duration: const Duration(seconds: 4)).listen(
      (device) {
        setState(() {
          if (device != null) {
            _devices.add(device);
          } else {
            _isScanning = false;
          }
        });
      },
    ).onError((Object error, _) {
      setState(() {
        _isScanning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).primaryColor,
          content: Text('$error'),
        ),
      );
    });
  }
}

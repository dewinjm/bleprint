// Copyright (c) 2022 Dewin J. Martinez
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:async';

import 'package:bleprint/src/bluetooth/bluetooth_device.dart';
import 'package:bleprint/src/bluetooth/bluetooth_manager_interface.dart';
import 'package:bleprint_platform_interface/bleprint_platform_interface.dart';

/// Bluetooth manager helpers
class BluetoothManager implements BluetoothManagerInterface {
  final _periodDefault = 2000;
  final _devices = <BluetoothDevice>[];
  final _resultStreamCtrl = StreamController<List<BluetoothDevice>>.broadcast();
  final _isScanningStreamCtrl = StreamController<bool>.broadcast();

  BleprintPlatform get _platform => BleprintPlatform.instance;

  @override
  Future<bool> get isAvailable async => _platform.isAvailable;

  @override
  Future<bool> get isEnabled async => _platform.isEnabled;

  @override
  Stream<List<BluetoothDevice>> get onScanResult => _resultStreamCtrl.stream;

  @override
  Stream<bool> get isScanning => _isScanningStreamCtrl.stream;

  @override
  Future<void> scanDevices({
    required Duration duration,
  }) {
    _isScanningStreamCtrl.add(true);
    _resultStreamCtrl.add(<BluetoothDevice>[]);
    _devices.clear();

    try {
      onMethodStream().drain(null);
      return _platform.scan(duration: duration.inMilliseconds);
    } catch (ex) {
      _isScanningStreamCtrl.add(false);
      return Future.error(ex);
    }
  }

  @override
  Stream<BluetoothDevice?> onMethodStream() async* {
    yield* _platform.methodStream.map((map) {
      switch (map.method) {
        case 'onDeviceState':
          final arg = map.arguments;
          if (arg is Map) {
            final device = BluetoothDevice.fromJson(
              Map<String, dynamic>.from(arg),
            );

            final index = _devices.indexWhere(
              (e) => e.address == device.address,
            );

            if (index == -1) return device;

            _devices[index]
                .stateStreamController
                .add(device.state ?? BluetoothDeviceState.disconnected);
            return device;
          }
          return null;

        case 'onStopScan':
          _isScanningStreamCtrl.add(false);
          _resultStreamCtrl.add(_devices);
          return null;

        case 'onScanResult':
          {
            final arg = map.arguments;
            if (arg is Map) {
              final device = BluetoothDevice.fromJson(
                Map<String, dynamic>.from(arg),
              );

              final index = _devices.indexWhere(
                (e) => e.address == device.address,
              );

              if (index != -1) {
                _devices[index] = device;
              } else {
                _devices.add(device);
                _resultStreamCtrl.add(_devices);
              }

              return device;
            }
          }
      }
      return null;
    });
  }

  @override
  Future<List<BluetoothDevice>> bondedDevices() async {
    return (await _platform.bondedDevices())
        .map((map) => BluetoothDevice.fromJson(Map<String, dynamic>.from(map!)))
        .toList();
  }

  @override
  Future<void> connect({
    required BluetoothDevice device,
    Duration? duration,
  }) {
    try {
      onMethodStream().drain(null);
      device.stateStreamController.sink.add(BluetoothDeviceState.connecting);

      return _platform.connect(
        deviceAddress: device.address,
        duration: duration == null ? _periodDefault : duration.inMilliseconds,
      );
    } catch (ex) {
      return Future.error(ex);
    }
  }

  @override
  Future<void> disconnect({required BluetoothDevice device}) {
    try {
      onMethodStream().drain(null);
      return _platform.disconnect(
        deviceAddress: device.address,
      );
    } catch (ex) {
      return Future.error(ex);
    }
  }
}

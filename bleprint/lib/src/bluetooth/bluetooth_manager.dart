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
  BleprintPlatform get _platform => BleprintPlatform.instance;

  @override
  Future<bool> get isAvailable async => _platform.isAvailable;

  @override
  Future<bool> get isEnabled async => _platform.isEnabled;

  @override
  Stream<BluetoothDevice> scanDevices({Duration? duration}) async* {
    duration ??= const Duration(seconds: 5);

    final streamController = StreamController<BluetoothDevice>.broadcast();
    final devices = <BluetoothDevice>[];

    _listenScan(duration: duration).handleError(
      (Object error, StackTrace stackTrace) {
        streamController.sink.addError(error, stackTrace);
      },
    ).listen(
      (device) async {
        if (device != null) {
          var newIndex = -1;

          devices.asMap().forEach((index, e) {
            if (e.address == device.address) {
              newIndex = index;
            }
          });

          if (newIndex != -1) {
            devices[newIndex] = device;
          } else {
            devices.add(device);
            streamController.sink.add(device);
          }
        }
      },
    );

    yield* streamController.stream;
  }

  Stream<BluetoothDevice?> _listenScan({required Duration duration}) async* {
    await _platform.scan(duration: duration.inMilliseconds);

    yield* _platform.methodStream.map((map) {
      switch (map.method) {
        case 'onStopScan':
          return null;

        case 'onScanResult':
          {
            final arg = map.arguments;
            if (arg is Map) {
              return BluetoothDevice.fromJson(Map<String, dynamic>.from(arg));
            }
          }
      }
      return null;
    });
  }
}

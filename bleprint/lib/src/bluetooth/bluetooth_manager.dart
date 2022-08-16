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

  BleprintPlatform get _platform => BleprintPlatform.instance;

  @override
  Future<bool> get isAvailable async => _platform.isAvailable;

  @override
  Future<bool> get isEnabled async => _platform.isEnabled;

  @override
  Stream<List<BluetoothDevice>> scanDevices({
    required Duration duration,
  }) async* {
    final streamController =
        StreamController<List<BluetoothDevice>>.broadcast();

    _listenScan(duration: duration).handleError(
      (Object error, StackTrace stackTrace) {
        streamController.sink.addError(error, stackTrace);
        streamController.close();
      },
    ).listen(
      (device) async {
        if (device != null) {
          var newIndex = -1;

          _devices.asMap().forEach((index, e) {
            if (e.address == device.address) {
              newIndex = index;
            }
          });

          if (newIndex != -1) {
            _devices[newIndex] = device;
          } else {
            _devices.add(device);
            streamController.sink.add(_devices);
          }
        } else {
          streamController.sink.add(_devices);
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

  @override
  Future<List<BluetoothDevice>> bondedDevices() async {
    return (await _platform.bondedDevices())
        .map((map) => BluetoothDevice.fromJson(Map<String, dynamic>.from(map!)))
        .toList();
  }

  @override
  Future<bool> connect({
    required BluetoothDevice device,
    Duration? duration,
  }) async {
    return _platform.connect(
      deviceAddress: device.address,
      duration: duration == null ? _periodDefault : duration.inMilliseconds,
    );
  }

  @override
  Future<bool> disconnect({
    required BluetoothDevice device,
  }) async {
    return _platform.disconnect(
      deviceAddress: device.address,
    );
  }
}

// Copyright (c) 2022 Dewin J. Martinez
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:bleprint/src/bluetooth/bluetooth_device.dart';

/// The interface that implementations of BluetoothManager must implement.
abstract class BluetoothManagerInterface {
  /// Return true if Bluetooth Adapter is available
  Future<bool> get isAvailable;

  /// Return true if BluetoothAdapter.STATE_ON is true
  Future<bool> get isEnabled;

  /// Starts scan Bluetooth devices
  ///
  /// `Duration` to stop scanning [duration]
  Stream<BluetoothDevice?> scanDevices({required Duration duration});

  /// Return the set of BluetoothDevice objects that are bonded (paired)
  /// to the local adapter.
  Future<List<BluetoothDevice>> bondedDevices();
}

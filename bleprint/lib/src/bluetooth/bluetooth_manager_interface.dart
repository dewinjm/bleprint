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

  /// Returns a stream boolean while scan is in progress
  ///
  /// emitted `true` when is start scan and
  /// emitted `false` when is stop scan
  Stream<bool> get isScanning;

  /// Starts scan Bluetooth devices
  ///
  /// `Duration` to stop scanning [duration]
  Future<void> scanDevices({
    required Duration duration,
  });

  /// Returns a stream that is a list of [BluetoothDevice]
  /// while a scan is in progress.
  Stream<List<BluetoothDevice>> get onScanResult;

  /// Return the set of BluetoothDevice objects that are bonded (paired)
  /// to the local adapter.
  Future<List<BluetoothDevice>> bondedDevices();

  /// Establishes a connection to the Bluetooth Device.
  Future<void> connect({
    required BluetoothDevice device,
    Duration? duration,
  });

  /// Cancels connection to the Bluetooth Device
  Future<void> disconnect({required BluetoothDevice device});

  /// Stream for platform invokeMethod
  Stream<BluetoothDevice?> onMethodStream();
}

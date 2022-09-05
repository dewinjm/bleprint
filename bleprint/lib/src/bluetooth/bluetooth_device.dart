// Copyright (c) 2022 Dewin J. Martinez
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:async';

/// Bluetooth device model
class BluetoothDevice {
  /// BluetoothDevice constructor
  BluetoothDevice({
    required this.name,
    required this.address,
    this.state = BluetoothDeviceState.disconnected,
  });

  /// Convert Map to BluetoothDevice model
  ///
  /// Json HashMap [json]
  BluetoothDevice.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        address = json['address'] as String,
        state = BluetoothDeviceState.values[(json['state'] as int?) ?? 0];

  /// Convert BluetoothDevice model to map
  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
      };

  /// Device name
  final String name;

  /// Device MAC address
  final String address;

  /// Device state [BluetoothDeviceState]
  final BluetoothDeviceState? state;

  /// Bluetooth device state broadcast
  final stateStreamController =
      StreamController<BluetoothDeviceState>.broadcast();

  /// Stream the current connection state of the device
  Stream<BluetoothDeviceState> get stateListener =>
      stateStreamController.stream;

  /// Creates a copy of BluetoothDevice but with the given fields
  /// replaced with the new values.
  BluetoothDevice copyWith({
    String? name,
    String? address,
    BluetoothDeviceState? state,
  }) =>
      BluetoothDevice(
        name: name ?? this.name,
        address: address ?? this.address,
        state: state ?? this.state,
      );
}

/// Bluetooth device connection state
enum BluetoothDeviceState {
  /// When is in disconnected state
  disconnected,

  /// State when device is connecting
  connecting,

  /// When is in connected state
  connected,

  /// When is in disconnecting state
  disconnecting,
}

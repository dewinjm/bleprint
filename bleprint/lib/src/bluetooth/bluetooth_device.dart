// Copyright (c) 2022 Dewin J. Martinez
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

/// Bluetooth device model
class BluetoothDevice {
  /// BluetoothDevice constructor
  BluetoothDevice({
    required this.name,
    required this.address,
    this.type = 0,
    this.isConnected = false,
  });

  /// Convert Map to BluetoothDevice model
  ///
  /// Json HashMap [json]
  BluetoothDevice.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        address = json['address'] as String,
        type = json['type'] as int,
        isConnected = json['isConnected'] as bool;

  /// Convert BluetoothDevice model to map
  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'type': type,
        'isConnected': isConnected,
      };

  /// Device name
  final String name;

  /// Device MAC address
  final String address;

  /// Device Type
  final int type;

  /// Device connect status
  final bool isConnected;
}

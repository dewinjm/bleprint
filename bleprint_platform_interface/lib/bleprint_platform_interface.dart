// Copyright (c) 2022 Dewin J. Martinez
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:bleprint_platform_interface/src/method_channel_bleprint.dart';
import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface that implementations of bleprint must implement.
///
/// Platform implementations should extend this class
/// rather than implement it as `Bleprint`.
/// Extending this class (using `extends`) ensures that the subclass will get
/// the default implementation, while platform implementations that `implements`
///  this interface will be broken by newly added [BleprintPlatform] methods.
abstract class BleprintPlatform extends PlatformInterface {
  /// Constructs a BleprintPlatform.
  BleprintPlatform() : super(token: _token);

  static final Object _token = Object();

  static BleprintPlatform _instance = MethodChannelBleprint();

  /// The default instance of [BleprintPlatform] to use.
  ///
  /// Defaults to [MethodChannelBleprint].
  static BleprintPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [BleprintPlatform] when they register themselves.
  static set instance(BleprintPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Starts scan Bluetooth devices
  ///
  /// Timer in milliseconds to stop scanning [duration]
  Future<void> scan({required int duration});

  /// Return true if Bluetooth Adapter is available
  Future<bool> get isAvailable;

  /// Return true if BluetoothAdapter.STATE_ON is true
  Future<bool> get isEnabled;

  /// Listen all Methods Calls invoke into each platform
  Stream<MethodCall> get methodStream;

  /// Return the set of BluetoothDevice objects that are bonded (paired)
  /// to the local adapter.
  Future<List<Map<String, dynamic>?>> bondedDevices();

  /// Connect bluetooth devices
  /// return true when connection is successful
  Future<bool> connect({required String deviceAddress, required int duration});

  /// Disconnect bluetooth devices
  /// return false when disconnection is successful
  Future<bool> disconnect({required String deviceAddress});
}

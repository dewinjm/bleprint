// Copyright (c) 2022 Dewin J. Martinez
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:async';

import 'package:bleprint_platform_interface/bleprint_platform_interface.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';

/// An implementation of [BleprintPlatform] that uses method channels.
class MethodChannelBleprint extends BleprintPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('bleprint');

  /// Method to add new invoke
  @visibleForTesting
  final StreamController<MethodCall> streamController =
      StreamController.broadcast();

  @override
  Future<String?> getPlatformName() async {
    return methodChannel.invokeMethod<String>('getPlatformName');
  }

  @override
  Future<void> scan({required int duration}) async {
    return methodChannel.invokeMethod('scan');
  }

  @override
  Future<bool> get isAvailable async => methodChannel
      .invokeMethod<bool>('isAvailable')
      .then((value) => value ?? false);

  @override
  Future<bool> get isEnabled async => methodChannel
      .invokeMethod<bool>('isEnabled')
      .then((value) => value ?? false);

  @override
  Stream<MethodCall> get methodStream => streamController.stream;

  @override
  Future<List<Map<String, dynamic>?>> bondedDevices() async {
    final objects = await methodChannel.invokeMethod<List<dynamic>>('paired');
    return objects != null
        ? objects.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : [];
  }
}

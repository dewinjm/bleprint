// Copyright (c) 2022 Dewin J. Martinez
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:async';

import 'package:bleprint_platform_interface/bleprint_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The Android implementation of [BleprintPlatform].
class BleprintAndroid extends BleprintPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('bleprint_android');

  final StreamController<MethodCall> _streamController =
      StreamController.broadcast();

  /// Add method into stream controller
  @visibleForTesting
  Future<void> addMethodCall(MethodCall call) {
    _streamController.add(call);
    return Future.value();
  }

  /// Registers this class as the default instance of [BleprintPlatform]
  static void registerWith() {
    BleprintPlatform.instance = BleprintAndroid();
  }

  @override
  Future<String?> getPlatformName() =>
      methodChannel.invokeMethod<String>('getPlatformName');

  @override
  Future<void> scan({required int duration}) =>
      methodChannel.invokeMethod('scan', duration);

  @override
  Future<bool> get isAvailable async => methodChannel
      .invokeMethod<bool>('isAvailable')
      .then((value) => value ?? false);

  @override
  Future<bool> get isEnabled async => methodChannel
      .invokeMethod<bool>('isEnabled')
      .then((value) => value ?? false);

  @override
  Stream<MethodCall> get methodStream {
    methodChannel
        .setMethodCallHandler((MethodCall call) async => addMethodCall(call));
    return _streamController.stream;
  }
}

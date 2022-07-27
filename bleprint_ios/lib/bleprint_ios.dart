// Copyright (c) 2022 Dewin J. Martinez
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:bleprint_platform_interface/bleprint_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The iOS implementation of [BleprintPlatform].
class BleprintIOS extends BleprintPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('bleprint_ios');

  /// Registers this class as the default instance of [BleprintPlatform]
  static void registerWith() {
    BleprintPlatform.instance = BleprintIOS();
  }

  @override
  Future<String?> getPlatformName() {
    return methodChannel.invokeMethod<String>('getPlatformName');
  }

  @override
  Future<void> startScan({required int duration}) {
    return methodChannel.invokeMethod('startScan', duration);
  }
}

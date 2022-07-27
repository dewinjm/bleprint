// Copyright (c) 2022 Dewin J. Martinez
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:bleprint_platform_interface/bleprint_platform_interface.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';

/// An implementation of [BleprintPlatform] that uses method channels.
class MethodChannelBleprint extends BleprintPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('bleprint');

  @override
  Future<String?> getPlatformName() async {
    return methodChannel.invokeMethod<String>('getPlatformName');
  }

  @override
  Future<void> scan({required int duration}) async {
    return methodChannel.invokeMethod('scan');
  }
}

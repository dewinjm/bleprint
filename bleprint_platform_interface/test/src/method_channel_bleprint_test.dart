// Copyright (c) 2022 Dewin J. Martinez
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:bleprint_platform_interface/src/method_channel_bleprint.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const kPlatformName = 'platformName';

  group('$MethodChannelBleprint', () {
    late MethodChannelBleprint methodChannelBleprint;
    final log = <MethodCall>[];

    setUp(() async {
      methodChannelBleprint = MethodChannelBleprint()
        ..methodChannel.setMockMethodCallHandler((MethodCall methodCall) async {
          log.add(methodCall);
          switch (methodCall.method) {
            case 'getPlatformName':
              return kPlatformName;
            case 'scan':
              return Future.value();
            default:
              return null;
          }
        });
    });

    tearDown(log.clear);

    test('getPlatformName', () async {
      final platformName = await methodChannelBleprint.getPlatformName();
      expect(
        log,
        <Matcher>[isMethodCall('getPlatformName', arguments: null)],
      );
      expect(platformName, equals(kPlatformName));
    });

    test('scan', () async {
      await methodChannelBleprint.scan(duration: 1000);

      expect(
        log,
        <Matcher>[isMethodCall('scan', arguments: null)],
      );
    });
  });
}

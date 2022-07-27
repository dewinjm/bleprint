// Copyright (c) 2022 Dewin J. Martinez
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:bleprint_android/bleprint_android.dart';
import 'package:bleprint_platform_interface/bleprint_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BleprintAndroid', () {
    const kPlatformName = 'Android';
    late BleprintAndroid bleprint;
    late List<MethodCall> log;

    setUp(() async {
      bleprint = BleprintAndroid();

      log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(bleprint.methodChannel, (methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'getPlatformName':
            return kPlatformName;
          case 'startScan':
            return Future.value();
          default:
            return null;
        }
      });
    });

    test('can be registered', () {
      BleprintAndroid.registerWith();
      expect(BleprintPlatform.instance, isA<BleprintAndroid>());
    });

    test('getPlatformName returns correct name', () async {
      final name = await bleprint.getPlatformName();
      expect(
        log,
        <Matcher>[isMethodCall('getPlatformName', arguments: null)],
      );
      expect(name, equals(kPlatformName));
    });

    test('verify to startScan is called', () async {
      const duration = 1000;
      await bleprint.startScan(duration: duration);

      expect(
        log,
        <Matcher>[isMethodCall('startScan', arguments: duration)],
      );
    });
  });
}

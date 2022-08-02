// Copyright (c) 2022 Dewin J. Martinez
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:bleprint_ios/bleprint_ios.dart';
import 'package:bleprint_platform_interface/bleprint_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BleprintIOS', () {
    const kPlatformName = 'iOS';
    late BleprintIOS bleprint;
    late List<MethodCall> log;

    setUp(() async {
      bleprint = BleprintIOS();
      log = <MethodCall>[];

      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(bleprint.methodChannel, (methodCall) async {
        log.add(methodCall);

        switch (methodCall.method) {
          case 'getPlatformName':
            return kPlatformName;
          case 'scan':
            return Future.value();
          case 'isAvailable':
            return true;
          case 'isEnabled':
            return true;
          case 'mockInvoke':
            await bleprint.addMethodCall(methodCall);
            return null;
          default:
            return null;
        }
      });
    });

    test('can be registered', () {
      BleprintIOS.registerWith();
      expect(BleprintPlatform.instance, isA<BleprintIOS>());
    });

    test('getPlatformName returns correct name', () async {
      final name = await bleprint.getPlatformName();
      expect(
        log,
        <Matcher>[isMethodCall('getPlatformName', arguments: null)],
      );
      expect(name, equals(kPlatformName));
    });

    test('verify to scan is called', () async {
      const duration = 1000;
      await bleprint.scan(duration: duration);

      expect(
        log,
        <Matcher>[isMethodCall('scan', arguments: duration)],
      );
    });

    test('isAvailable returns correct value', () async {
      final value = await bleprint.isAvailable;
      expect(
        log,
        <Matcher>[isMethodCall('isAvailable', arguments: null)],
      );
      expect(value, isTrue);
    });

    test('isEnabled returns correct value', () async {
      final value = await bleprint.isEnabled;
      expect(
        log,
        <Matcher>[isMethodCall('isEnabled', arguments: null)],
      );
      expect(value, isTrue);
    });

    test('should call invokeMethod', () async {
      await bleprint.methodChannel.invokeMethod('mockInvoke');
      expect(log, <Matcher>[isMethodCall('mockInvoke', arguments: null)]);

      final value = bleprint.methodStream;
      expect(value.isBroadcast, isTrue);
    });
  });
}

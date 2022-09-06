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
    const mockDevicesJson = [
      {
        'name': 'device #1',
        'address': 'address #1',
        'type': 0,
        'isConnected': false
      },
      {
        'name': 'device #2',
        'address': 'address #2',
        'type': 2,
        'isConnected': false
      },
    ];

    late BleprintIOS bleprint;
    late List<MethodCall> log;
    var isPairedNull = false;

    setUp(() async {
      bleprint = BleprintIOS();
      log = <MethodCall>[];

      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(bleprint.methodChannel, (methodCall) async {
        log.add(methodCall);

        switch (methodCall.method) {
          case 'scan':
            return Future.value();
          case 'isAvailable':
            return true;
          case 'isEnabled':
            return true;
          case 'paired':
            return isPairedNull ? null : mockDevicesJson;
          case 'connect':
            return true;
          case 'disconnect':
            return false;
          case 'mockInvoke':
            await bleprint.addMethodCall(methodCall);
            return null;
          default:
            return null;
        }
      });
    });

    tearDown(() {
      log.clear();
      isPairedNull = false;
    });

    test('can be registered', () {
      BleprintIOS.registerWith();
      expect(BleprintPlatform.instance, isA<BleprintIOS>());
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

    group('bondedDevices', () {
      test('should return list map', () async {
        final result = await bleprint.bondedDevices();

        expect(log, <Matcher>[isMethodCall('paired', arguments: null)]);
        expect(result, equals(mockDevicesJson));
      });

      test('should return empty list map when is null', () async {
        isPairedNull = true;
        final result = await bleprint.bondedDevices();

        expect(log, <Matcher>[isMethodCall('paired', arguments: null)]);
        expect(result, equals([]));
      });
    });

    test('connect should return true when connection is successful', () async {
      final value = await bleprint.connect(
        deviceAddress: 'deviceAddress',
        duration: 1000,
      );

      expect(log, <Matcher>[
        isMethodCall('connect', arguments: ['deviceAddress', 1000]),
      ]);
      expect(value, isTrue);
    });

    test('should return false when disconnection is successful', () async {
      final value = await bleprint.disconnect(deviceAddress: 'deviceAddress');

      expect(
        log,
        <Matcher>[isMethodCall('disconnect', arguments: 'deviceAddress')],
      );
      expect(value, isFalse);
    });
  });
}

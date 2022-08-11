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

  group('$MethodChannelBleprint', () {
    late MethodChannelBleprint methodChannelBleprint;
    final log = <MethodCall>[];
    var isPairedNull = false;

    setUp(() async {
      methodChannelBleprint = MethodChannelBleprint()
        ..methodChannel.setMockMethodCallHandler((MethodCall methodCall) async {
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
            case 'paired':
              return isPairedNull ? null : mockDevicesJson;
            case 'mockInvoke':
              {
                methodChannelBleprint.methodChannel.setMethodCallHandler(
                  (MethodCall call) async {
                    methodChannelBleprint.streamController.add(call);
                    return Future(() => null);
                  },
                );
                break;
              }
            default:
              return null;
          }
        });
    });

    tearDown(() {
      log.clear();
      isPairedNull = false;
    });

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

    test('isAvailable', () async {
      final value = await methodChannelBleprint.isAvailable;

      expect(log, <Matcher>[isMethodCall('isAvailable', arguments: null)]);
      expect(value, isTrue);
    });

    test('isEnabled', () async {
      final value = await methodChannelBleprint.isEnabled;

      expect(log, <Matcher>[isMethodCall('isEnabled', arguments: null)]);
      expect(value, isTrue);
    });

    test('methodStream', () async {
      await methodChannelBleprint.methodChannel.invokeMethod('mockInvoke');

      final value = methodChannelBleprint.methodStream;

      expect(log, <Matcher>[isMethodCall('mockInvoke', arguments: null)]);
      expect(value.isBroadcast, isTrue);
    });

    group('bondedDevices', () {
      test('should return list map', () async {
        final result = await methodChannelBleprint.bondedDevices();

        expect(log, <Matcher>[isMethodCall('paired', arguments: null)]);
        expect(result, equals(mockDevicesJson));
      });

      test('should return empty list map when is null', () async {
        isPairedNull = true;
        final result = await methodChannelBleprint.bondedDevices();

        expect(log, <Matcher>[isMethodCall('paired', arguments: null)]);
        expect(result, equals([]));
      });
    });
  });
}

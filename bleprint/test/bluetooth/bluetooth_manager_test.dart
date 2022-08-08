// Copyright (c) 2022 Dewin J. Martinez
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:bleprint/src/bluetooth/bluetooth.dart';
import 'package:bleprint_platform_interface/bleprint_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBleprintPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements BleprintPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BluetoothManager', () {
    late BleprintPlatform bleprintPlatform;
    late BluetoothManager bluetoothManager;

    setUp(() {
      bleprintPlatform = MockBleprintPlatform();
      BleprintPlatform.instance = bleprintPlatform;

      bluetoothManager = BluetoothManager();
    });

    group('isAvailable', () {
      test('should return true when platform.isAvailable is true', () async {
        when(
          () => bleprintPlatform.isAvailable,
        ).thenAnswer((_) async => true);

        final result = await bluetoothManager.isAvailable;
        expect(result, isTrue);
      });

      test('should return false when platform.isAvailable is false', () async {
        when(
          () => bleprintPlatform.isAvailable,
        ).thenAnswer((_) async => false);

        final result = await bluetoothManager.isAvailable;
        expect(result, isFalse);
      });
    });

    group('isEnabled', () {
      test('should return true when platform.isEnabled is true', () async {
        when(
          () => bleprintPlatform.isEnabled,
        ).thenAnswer((_) async => true);

        final result = await bluetoothManager.isEnabled;
        expect(result, isTrue);
      });

      test('should return false when platform.isEnabled is false', () async {
        when(
          () => bleprintPlatform.isEnabled,
        ).thenAnswer((_) async => false);

        final result = await bluetoothManager.isEnabled;
        expect(result, isFalse);
      });
    });

    group('scanDevices', () {
      test('should return onScanResult method stream', () async {
        const duration = Duration(milliseconds: 1000);
        when(
          () => bleprintPlatform.scan(duration: duration.inMilliseconds),
        ).thenAnswer((_) async => Future.value());

        final fakeDevice = BluetoothDevice(
          name: 'deviceABC',
          address: 'address',
        );

        final method1 = MethodCall('onScanResult', fakeDevice.toJson());
        final method2 = MethodCall('onScanResult', fakeDevice.toJson());

        when(
          () => bleprintPlatform.methodStream,
        ).thenAnswer((_) {
          return Stream.multi((met) {
            met
              ..add(method1)
              ..add(method2);
          });
        });

        bluetoothManager.scanDevices(duration: duration).listen(
          expectAsync1(
            (device) {
              expect(device!.name, equals(fakeDevice.name));
              expect(device.address, equals(fakeDevice.address));
            },
          ),
        );
      });

      test('should return onStopScan method stream', () async {
        const duration = Duration(milliseconds: 1000);
        when(
          () => bleprintPlatform.scan(duration: duration.inMilliseconds),
        ).thenAnswer((_) async => Future.value());

        final fakeDevice = BluetoothDevice(
          name: 'deviceABC',
          address: 'address',
        );

        when(
          () => bleprintPlatform.methodStream,
        ).thenAnswer((_) {
          return Stream.value(MethodCall('onStopScan', fakeDevice.toJson()));
        });

        bluetoothManager.scanDevices(duration: duration).listen(
          expectAsync1(
            (device) {
              expect(device, isNull);
            },
          ),
        );
      });

      test('should throw Exception when has error', () async {
        const duration = Duration(milliseconds: 1000);
        when(
          () => bleprintPlatform.scan(duration: duration.inMilliseconds),
        ).thenThrow(Exception('Fake Error'));

        final fakeDevice = BluetoothDevice(
          name: 'deviceABC',
          address: 'address',
        );

        final method = MethodCall('onScanResult', fakeDevice.toJson());

        when(() => bleprintPlatform.methodStream).thenAnswer((_) {
          return Stream.value(method);
        });

        final stream = bluetoothManager.scanDevices(duration: duration);
        await expectLater(stream, emitsInOrder([]));
      });
    });
  });
}

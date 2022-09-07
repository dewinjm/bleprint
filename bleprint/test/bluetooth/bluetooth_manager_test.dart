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
        const duration = Duration(milliseconds: 500);

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

        bluetoothManager.isScanning.listen(
          expectAsync1((value) {
            expect(value, isTrue);
          }),
        );

        await bluetoothManager.scanDevices(duration: duration);

        bluetoothManager.onScanResult.listen(
          expectAsync1(
            (devices) {
              expect(devices.length, equals(1));
              expect(devices.first.name, equals(fakeDevice.name));
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

        await bluetoothManager.scanDevices(duration: duration);

        bluetoothManager.onScanResult.listen(
          expectAsync1(
            (device) {
              expect(device, List<BluetoothDevice>.empty());
            },
          ),
        );
      });

      test('should throw Exception when has error', () async {
        const duration = Duration(milliseconds: 1000);

        when(
          () => bleprintPlatform.scan(duration: duration.inMilliseconds),
        ).thenThrow(Exception('Fake Error'));

        const method = MethodCall('otherMethod');

        when(() => bleprintPlatform.methodStream).thenAnswer((_) {
          return Stream.value(method);
        });

        final res = bluetoothManager.scanDevices(duration: duration);
        expect(res, throwsA(isA<Exception>()));
      });
    });

    group('bondedDevices', () {
      test('should return a list of BluetoothDevice', () async {
        when(
          () => bleprintPlatform.bondedDevices(),
        ).thenAnswer(
          (_) async => [
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
          ],
        );

        final result = await bluetoothManager.bondedDevices();
        expect(result, isList);
        expect(result.length, equals(2));
      });
    });

    group('connect', () {
      test('should return true when connection is successfull', () async {
        const devicesAddress = 'mockAddress';
        const timeout = 2000;

        when(
          () => bleprintPlatform.connect(
            deviceAddress: devicesAddress,
            duration: timeout,
          ),
        ).thenAnswer((_) async => true);

        final device = BluetoothDevice(
          name: 'Device abc',
          address: devicesAddress,
        );

        final deviceResponse = {
          'name': 'Device abs',
          'address': 'mockAddress',
          'state': 2
        };

        final scanResult = MethodCall('onScanResult', device.toJson());
        final deviceState = MethodCall('onDeviceState', deviceResponse);

        when(
          () => bleprintPlatform.methodStream,
        ).thenAnswer((_) {
          return Stream.multi((met) {
            met
              ..add(scanResult)
              ..add(deviceState);
          });
        });

        final result = bluetoothManager.connect(
          device: device,
          duration: const Duration(milliseconds: timeout),
        );

        expect(result, completes);

        bluetoothManager.onScanResult.listen((devices) {
          devices[0].stateListener.listen(
            expectAsync1((state) {
              expect(state, equals(BluetoothDeviceState.connected));
            }),
          );
        });
      });

      test('should throw Exception when has error', () {
        const devicesAddress = 'mockAddress';
        const timeout = 2000;

        when(
          () => bleprintPlatform.connect(
            deviceAddress: devicesAddress,
            duration: timeout,
          ),
        ).thenThrow(Exception('Fake Exception'));

        when(() => bleprintPlatform.methodStream).thenAnswer((_) {
          return Stream.value(const MethodCall('otherMethod'));
        });

        final device = BluetoothDevice(
          name: 'Device abc',
          address: devicesAddress,
        );

        final result = bluetoothManager.connect(
          device: device,
          duration: const Duration(milliseconds: timeout),
        );

        expect(result, throwsA(isA<Exception>()));
      });
    });

    group('disconnect', () {
      test(
        'should return false when disconnection is successfull',
        () async {
          const devicesAddress = 'mockAddress';

          when(
            () => bleprintPlatform.disconnect(deviceAddress: devicesAddress),
          ).thenAnswer((_) async => true);

          final device = BluetoothDevice(
            name: 'Device abc',
            address: devicesAddress,
          );

          final deviceResponse = {
            'name': 'Device abs',
            'address': 'mockAddress',
            'state': 0
          };

          final scanResult = MethodCall('onScanResult', device.toJson());
          final deviceState = MethodCall('onDeviceState', deviceResponse);

          when(
            () => bleprintPlatform.methodStream,
          ).thenAnswer((_) {
            return Stream.multi((met) {
              met
                ..add(scanResult)
                ..add(deviceState);
            });
          });

          final result = bluetoothManager.disconnect(device: device);
          expect(result, completes);

          bluetoothManager.onScanResult.listen((devices) {
            devices[0].stateListener.listen(
              expectAsync1((state) {
                expect(state, equals(BluetoothDeviceState.disconnected));
              }),
            );
          });
        },
      );

      test('should throw Exception when has error', () {
        const devicesAddress = 'mockAddress';

        when(
          () => bleprintPlatform.disconnect(deviceAddress: devicesAddress),
        ).thenThrow(Exception('Fake Exception'));

        when(() => bleprintPlatform.methodStream).thenAnswer((_) {
          return Stream.value(const MethodCall('otherMethod'));
        });

        final device = BluetoothDevice(
          name: 'Device abc',
          address: devicesAddress,
        );

        final result = bluetoothManager.disconnect(device: device);
        expect(result, throwsA(isA<Exception>()));
      });
    });
  });
}

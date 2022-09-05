// Copyright (c) 2022 Dewin J. Martinez
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:bleprint/src/bluetooth/bluetooth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bluetooth Device Model', () {
    final jsonMock = {
      'name': 'device name',
      'address': 'address',
      'state': 0,
    };

    final deviceMock = BluetoothDevice(
      name: 'name',
      address: 'address',
    );

    group('fromJson', () {
      test('should return a valid model when the JSON is correct', () {
        final deviceData = BluetoothDevice.fromJson(jsonMock);

        expect(deviceData.name, 'device name');
        expect(deviceData.address, 'address');
        expect(deviceData.state, BluetoothDeviceState.disconnected);
      });
    });

    group('toJson', () {
      test('should return a JSON map containing the proper data', () {
        final result = deviceMock.toJson();

        final expectedMap = {
          'name': 'name',
          'address': 'address',
        };

        expect(result, expectedMap);
      });
    });

    group('copyWith', () {
      test('should create a copy of BluetoothDevice', () {
        final mockCopy = deviceMock.copyWith();
        expect(mockCopy.name, equals(deviceMock.copyWith().name));

        final device = deviceMock.copyWith(
          name: 'ABC',
          address: 'new address',
          state: BluetoothDeviceState.connected,
        );

        expect(device.name, equals('ABC'));
        expect(device.address, equals('new address'));
        expect(device.state, equals(BluetoothDeviceState.connected));
      });
    });
  });
}

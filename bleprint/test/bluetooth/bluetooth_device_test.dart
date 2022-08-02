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
      'type': 0,
      'isConnected': false
    };

    final deviceMock = BluetoothDevice(
      name: 'name',
      address: 'address',
      type: 1,
      isConnected: true,
    );

    group('fromJson', () {
      test('should return a valid model when the JSON is correct', () {
        final deviceData = BluetoothDevice.fromJson(jsonMock);
        expect(deviceData.name, 'device name');
        expect(deviceData.address, 'address');
        expect(deviceData.type, 0);
        expect(deviceData.isConnected, false);
      });
    });

    group('toJson', () {
      test('should return a JSON map containing the proper data', () {
        final result = deviceMock.toJson();

        final expectedMap = {
          'name': 'name',
          'address': 'address',
          'type': 1,
          'isConnected': true,
        };

        expect(result, expectedMap);
      });
    });
  });
}

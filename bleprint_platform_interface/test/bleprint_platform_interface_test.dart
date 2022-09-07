// Copyright (c) 2022 Dewin J. Martinez
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:async';
import 'package:bleprint_platform_interface/bleprint_platform_interface.dart';
import 'package:flutter/src/services/message_codec.dart';
import 'package:flutter_test/flutter_test.dart';

class BleprintMock extends BleprintPlatform {
  static const mockDevicesJson = [
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

  final StreamController<MethodCall> _streamController =
      StreamController.broadcast();

  @override
  Future<void> scan({required int duration}) async {}

  @override
  Future<bool> get isAvailable async => true;

  @override
  Future<bool> get isEnabled async => true;

  @override
  Stream<MethodCall> get methodStream => _streamController.stream;

  @override
  Future<List<Map<String, dynamic>>> bondedDevices() =>
      Future.value(mockDevicesJson);

  @override
  Future<bool> connect({
    required String deviceAddress,
    required int duration,
  }) async =>
      true;

  @override
  Future<bool> disconnect({required String deviceAddress}) async {
    return false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BleprintPlatformInterface', () {
    late BleprintPlatform bleprintPlatform;

    setUp(() {
      bleprintPlatform = BleprintMock();
      BleprintPlatform.instance = bleprintPlatform;
    });

    group('scan', () {
      test('verify it is called', () async {
        expect(
          BleprintPlatform.instance.scan(duration: 1000),
          completes,
        );
      });
    });

    group('isAvailable', () {
      test('should return true', () async {
        expect(await BleprintPlatform.instance.isAvailable, isTrue);
      });
    });

    group('isEnabled', () {
      test('should return true', () async {
        expect(await BleprintPlatform.instance.isEnabled, isTrue);
      });
    });

    group('methodStream', () {
      test('should return stream', () async {
        expect(
          BleprintPlatform.instance.methodStream,
          isInstanceOf<Stream<MethodCall>>(),
        );
      });
    });

    group('bondedDevices', () {
      test('should return list of bluetooth bonded', () async {
        expect(
          await BleprintPlatform.instance.bondedDevices(),
          BleprintMock.mockDevicesJson,
        );
      });
    });

    group('connect', () {
      test('should return true when connection is successful', () async {
        expect(
          await BleprintPlatform.instance.connect(
            deviceAddress: 'fake_address',
            duration: 2000,
          ),
          isTrue,
        );
      });
    });

    group('disconnect', () {
      test('should return false when disconnection is successful', () async {
        expect(
          await BleprintPlatform.instance.disconnect(
            deviceAddress: 'fake_address',
          ),
          isFalse,
        );
      });
    });
  });
}

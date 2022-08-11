// Copyright (c) 2022 Dewin J. Martinez
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'dart:async';
import 'package:bleprint_platform_interface/bleprint_platform_interface.dart';
import 'package:flutter/src/services/message_codec.dart';
import 'package:flutter_test/flutter_test.dart';

class BleprintMock extends BleprintPlatform {
  static const mockPlatformName = 'Mock';
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
  Future<String?> getPlatformName() async => mockPlatformName;

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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BleprintPlatformInterface', () {
    late BleprintPlatform bleprintPlatform;

    setUp(() {
      bleprintPlatform = BleprintMock();
      BleprintPlatform.instance = bleprintPlatform;
    });

    group('getPlatformName', () {
      test('returns correct name', () async {
        expect(
          await BleprintPlatform.instance.getPlatformName(),
          equals(BleprintMock.mockPlatformName),
        );
      });
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
  });
}

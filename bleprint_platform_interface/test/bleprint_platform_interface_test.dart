// Copyright (c) 2022 Dewin J. Martinez
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:bleprint_platform_interface/bleprint_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class BleprintMock extends BleprintPlatform {
  static const mockPlatformName = 'Mock';

  @override
  Future<String?> getPlatformName() async => mockPlatformName;

  @override
  Future<void> startScan({required int duration}) async {}
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

    group('startScan', () {
      test('verify to startScan is called', () async {
        expect(
          BleprintPlatform.instance.startScan(duration: 1000),
          completes,
        );
      });
    });
  });
}

// Copyright (c) 2022, Very Good Ventures
// https://verygood.ventures
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:bleprint_platform_interface/bleprint_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class BleprintMock extends BleprintPlatform {
  static const mockPlatformName = 'Mock';

  @override
  Future<String?> getPlatformName() async => mockPlatformName;
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
  });
}

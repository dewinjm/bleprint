// Copyright (c) 2022, Very Good Ventures
// https://verygood.ventures
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:bleprint_platform_interface/bleprint_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBleprintPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements BleprintPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bleprint', () {
    late BleprintPlatform bleprintPlatform;

    setUp(() {
      bleprintPlatform = MockBleprintPlatform();
      BleprintPlatform.instance = bleprintPlatform;
    });
  });
}

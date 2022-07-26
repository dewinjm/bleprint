// Copyright (c) 2022, Very Good Ventures
// https://verygood.ventures
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:bleprint_platform_interface/src/method_channel_bleprint.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface that implementations of bleprint must implement.
///
/// Platform implementations should extend this class
/// rather than implement it as `Bleprint`.
/// Extending this class (using `extends`) ensures that the subclass will get
/// the default implementation, while platform implementations that `implements`
///  this interface will be broken by newly added [BleprintPlatform] methods.
abstract class BleprintPlatform extends PlatformInterface {
  /// Constructs a BleprintPlatform.
  BleprintPlatform() : super(token: _token);

  static final Object _token = Object();

  static BleprintPlatform _instance = MethodChannelBleprint();

  /// The default instance of [BleprintPlatform] to use.
  ///
  /// Defaults to [MethodChannelBleprint].
  static BleprintPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [BleprintPlatform] when they register themselves.
  static set instance(BleprintPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Return the current platform name.
  Future<String?> getPlatformName();
}

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'menubar_method_channel.dart';

abstract class MenubarPlatform extends PlatformInterface {
  /// Constructs a MenubarPlatform.
  MenubarPlatform() : super(token: _token);

  static final Object _token = Object();

  static MenubarPlatform _instance = MethodChannelMenubar();

  /// The default instance of [MenubarPlatform] to use.
  ///
  /// Defaults to [MethodChannelMenubar].
  static MenubarPlatform get instance => _instance;
  
  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MenubarPlatform] when
  /// they register themselves.
  static set instance(MenubarPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

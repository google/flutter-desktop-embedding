import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'menubar_platform_interface.dart';

/// An implementation of [MenubarPlatform] that uses method channels.
class MethodChannelMenubar extends MenubarPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('menubar');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}

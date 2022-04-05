
import 'menubar_platform_interface.dart';

class Menubar {
  Future<String?> getPlatformVersion() {
    return MenubarPlatform.instance.getPlatformVersion();
  }
}

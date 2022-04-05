import 'package:flutter_test/flutter_test.dart';
import 'package:menubar/menubar.dart';
import 'package:menubar/menubar_platform_interface.dart';
import 'package:menubar/menubar_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMenubarPlatform 
    with MockPlatformInterfaceMixin
    implements MenubarPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final MenubarPlatform initialPlatform = MenubarPlatform.instance;

  test('$MethodChannelMenubar is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMenubar>());
  });

  test('getPlatformVersion', () async {
    Menubar menubarPlugin = Menubar();
    MockMenubarPlatform fakePlatform = MockMenubarPlatform();
    MenubarPlatform.instance = fakePlatform;
  
    expect(await menubarPlugin.getPlatformVersion(), '42');
  });
}

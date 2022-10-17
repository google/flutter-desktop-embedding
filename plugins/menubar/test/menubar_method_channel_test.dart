import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menubar/menubar_method_channel.dart';

void main() {
  MethodChannelMenubar platform = MethodChannelMenubar();
  const MethodChannel channel = MethodChannel('menubar');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}

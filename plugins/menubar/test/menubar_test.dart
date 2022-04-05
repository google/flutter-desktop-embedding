// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
    MenubarPlatform old = MenubarPlatform.instance;
    MockMenubarPlatform fakePlatform = MockMenubarPlatform();
    MenubarPlatform.instance = fakePlatform;
  
    expect(await menubarPlugin.getPlatformVersion(), '42');
    MenubarPlatform.instance = old;
  });
}

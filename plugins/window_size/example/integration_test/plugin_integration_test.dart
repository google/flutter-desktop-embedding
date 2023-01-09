// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://docs.flutter.dev/cookbook/testing/integration/introduction

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:window_size/window_size.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getWindowInfo sanity check', (tester) async {
    final windowInfo = await getWindowInfo();
    expect(windowInfo.frame.isEmpty, isFalse);
    expect(windowInfo.scaleFactor > 0, isTrue);
    expect(windowInfo.screen, isNotNull);
  });
}

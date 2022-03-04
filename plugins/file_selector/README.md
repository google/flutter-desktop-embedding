# file_selector Desktop Implementations

This folder contains the unendorsed Linux implementation of the
[`file_selector`](https://github.com/flutter/plugins/tree/master/packages/file_selector)
plugin. It is not currently
[endorsed](https://flutter.dev/docs/development/packages-and-plugins/developing-packages#endorsed-federated-plugin),
and is here rather than in the flutter/plugins repository, because
it has not yet been refactored to support thorough
unit testing, and so it doesn't meet the Flutter testing
requirements. Once automated tests are developed, it will be moved to
flutter/plugins and endorsed (as has already happened with Windows and
macOS).

Unlike other FDE plugins it is published normally, since it has a
long-term support path. As with any unundorsed plugin, you need to
depend directly on the implementation package
([`file_selector_linux`](https://pub.dev/packages/file_selector_linux))
as well as the app-facing package (`file_selector`) in your `pubspec.yaml`.

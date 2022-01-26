# file_selector Desktop Implementations

This folder contains unendorsed macOS and Linux implementations of the
[`file_selector`](https://github.com/flutter/plugins/tree/master/packages/file_selector)
plugin. They are not currently
[endorsed](https://flutter.dev/docs/development/packages-and-plugins/developing-packages#endorsed-federated-plugin),
and are here rather than in the flutter/plugins repository, because
there is not yet test infrastructure in place to test desktop plugins that
show native UI, and they have not yet been refactored to support thorough
unit testing, and so these implementations don't meet the Flutter testing
requirements. Once automated tests are developed, they will be moved to
flutter/plugins and endorsed.

Unlike other FDE plugins these are published normally, since they have a
long-term support path. As with any unundorsed plugin, you need to
depend directly on the implementation package
([`file_selector_linux`](https://pub.dev/packages/file_selector_linux) and/or
[`file_selector_macos`](https://pub.dev/packages/file_selector_macos))
as well as the app-facing package (`file_selector`) in your `pubspec.yaml`.

See the implementation packages' READMEs for platform-specific notes.

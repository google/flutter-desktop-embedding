# Flutter Application Requirements

Because desktop platforms are not supported Flutter targets, existing Flutter
applications are likely to require slight modifications to run.

## Target Platform Override

Most applications will need to override the target platform for the application
to one of the supported values in order to avoid 'Unknown platform' exceptions.
This should be done as early as possible.

In the simplest case, where the code will only run on desktop and the behavior
should be consistent on all platforms, you can hard-code a single target:

```dart
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
[...]

void main() {
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  [...]
}
```

If the code needs to run on both mobile and desktop, or you want different
behavior on different desktop platforms, you can conditionalize on `Platform`.
For example, the line in `main()` above could be replaced with a call to:

```dart
/// If the current platform is desktop, override the default platform to
/// a supported platform (iOS for macOS, Android for Linux and Windows).
/// Otherwise, do nothing.
void _setTargetPlatformForDesktop() {
  TargetPlatform targetPlatform;
  if (Platform.isMacOS) {
    targetPlatform = TargetPlatform.iOS;
  } else if (Platform.isLinux || Platform.isWindows) {
    targetPlatform = TargetPlatform.android;
  }
  if (targetPlatform != null) {
    debugDefaultTargetPlatformOverride = targetPlatform;
  }
}
```

Note that the target platform you use will affect not only the behavior and
appearance of the widgets, but also the expectations Flutter will have for
what is available on the platform, such as fonts.

## Fonts

Flutter applications may default to fonts that are standard for the target
platform, but unavailable on desktop. For instance, if the target platform is
`TargetPlatform.iOS` the Material library will default to San Francisco, which
is available on macOS but not Linux or Windows.

Most applications will need to set the font (e.g., via `ThemeData`) based
on the host platform, or set a specific font that is bundled with the
application. The example application demonstrates using and bundling Roboto
on all platforms.

Symptoms of missing fonts can include text failing to display, console logging
about failure to load fonts, or in some cases crashes.

## Plugins

If your project uses any plugins with platform components, they won't
work, as the native side will be missing. Depending on how the Dart side of the
plugin is written, they may fail gracefully, or may throw errors.

You may need to make the calls to those plugins conditional based on the host
platform. Alternately, if you have the expertise, you could implement the native
side of the plugin in your desktop project(s).

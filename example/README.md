# Desktop Flutter Example

This is the standard Flutter template application, modified to run on desktop.

The `linux`, `macos`, and `windows` directories serve as early prototypes of
what will eventually become the `flutter create` templates for desktop, and will
be evolving over time to better reflect that goal.

## Building and Running

See [the main project README](../README.md).

To build without running, use `flutter build macos`/`windows`/`linux` rather than `flutter run`, as with
a standard Flutter project.

## Dart Differences from Flutter Template

The `main.dart` and `pubspec.yaml` have minor changes to support desktop:
* `debugDefaultTargetPlatformOverride` is set to avoid 'Unknown platform'
  exceptions.
* The font is explicitly set to Roboto, and Roboto is bundled via
  `pubspec.yaml`, to ensure that text displays on all platforms.

See the [Flutter Application Requirements section of the Flutter page on
desktop support](https://github.com/flutter/flutter/wiki/Desktop-shells#flutter-application-requirements)
for more information.

## Adapting for Another Project

Since `flutter create` is not yet supported for desktop, the easiest way to
try out desktop support with an existing Flutter application is to start
from this example. Two different approaches are described below.

With either approach, be sure to read the [Flutter page on desktop
support](https://github.com/flutter/flutter/wiki/Desktop-shells), especially
the [Flutter Application Requirements
section](https://github.com/flutter/flutter/wiki/Desktop-shells#flutter-application-requirements).

If you are building for macOS, you should also read about [managing macOS
security configurations](../macOS-Security.md).

### Copy the 'linux', 'macos', and/or 'windows' Directories

These directories are self-contained, and can be copied to an existing
Flutter project, enabling `flutter run` for those platforms.

**Be aware that neither the API surface of the Flutter desktop libraries nor the
interaction between the `flutter` tool and the platform directories is stable,
and no attempt will be made to provide supported migration paths as things
change.** If you use this approach, you should expect that every time you
update Flutter you may have to delete your copies of the platform
directories and re-copy them from an updated version of
flutter-desktop-embedding.

### Replace Flutter Components

Since this example already supports running on desktop platforms, you can
swap in your project's Dart code, `pubspec.yaml`, resources, etc.

This will be the easiest approach to keep working as desktop support evolves,
but requires that you develop your project in a flutter-desktop-embedding
fork.

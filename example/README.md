# Desktop Flutter Example

This is the standard Flutter template application, modified to run on desktop.

The `linux` and `windows` directories serve as early prototypes of
what will eventually become the `flutter create` templates for desktop, and will
be evolving over time to better reflect that goal. The `macos` directory has
now become a `flutter create` template, so is largely identical to what that
command creates.

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

Since `flutter create` is not yet supported for Windows and Linux, the easiest
way to try out desktop support with an existing Flutter application on those
platforms is to copy the platform directories from this example; see below for
details. For macOS, just run `flutter create .` in your project, which will
create the macOS folder (as long as you have macOS support enabled in `flutter`).

Be sure to read the [Flutter page on desktop
support](https://github.com/flutter/flutter/wiki/Desktop-shells) before trying to
run an existing project on desktop, especially the [Flutter Application Requirements
section](https://github.com/flutter/flutter/wiki/Desktop-shells#flutter-application-requirements).

### Copying the Desktop Runners

The 'linux' and 'windows' directories are self-contained, and can be copied to
an existing Flutter project, enabling `flutter run` for those platforms.

**Be aware that neither the API surface of the Flutter desktop libraries nor the
interaction between the `flutter` tool and the platform directories is stable,
and no attempt will be made to provide supported migration paths as things
change.** You should expect that every time you update Flutter you may have
to delete your copies of the platform directories and re-copy them from an
updated version of flutter-desktop-embedding.

### Customizing the Runners

See [Application Customization](App-Customization.md) for premilinary
documenation on modifying basic application information like name and icon.

If you are building for macOS, you should also read about [managing macOS
security configurations](../macOS-Security.md).

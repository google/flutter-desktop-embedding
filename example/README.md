# Desktop Flutter Example

This is the standard Flutter template application, with desktop platform
directories added.

The `windows` directory is an early version of what will become the
`flutter create` template. The `macos` and `linux` directories already have
become templates, so are almost identical to what that command command creates.

## Building and Running

See [the main project README](../README.md).

To build without running, use `flutter build macos`/`windows`/`linux` rather than `flutter run`, as with
a standard Flutter project.

## Differences from Flutter Template

The `main.dart` and `pubspec.yaml` have been adjusted to explicitly
set the font to Roboto, and to bundle Roboto in the app, to ensure
that text displays on all platforms. Due to recent changes in Flutter,
this should no longer be necessary for most apps.

## Adapting for Another Project

Since `flutter create` is not yet supported for Windows, the easiest
way to run an existing Flutter application on Windows is to copy the `windows`
directory from this example; see below for details.

For macOS or Linux, just run `flutter create .` in your project to add
the platform directory.

### Copying the Desktop Runners

The `windows` directory is self-contained, and can be copied to
an existing Flutter project to enable `flutter run -d windows`.

**Be aware that breaking changes in the Flutter desktop libraries and tooling
are common, and no attempt will be made to provide supported migration paths
as things change.** You should expect that every time you update Flutter you may
have to delete your copy of the `windows` directories and re-copy it from an
updated version of this repository.

### Customizing the Runners

See [Application Customization](App-Customization.md) for premilinary
documenation on modifying basic application information like name and icon.

If you are building for macOS, you should also read about [managing macOS
security configurations](../macOS-Security.md).

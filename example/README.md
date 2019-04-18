# Desktop Flutter Example

This application shows an example of how to use the [desktop
libraries](https://github.com/flutter/flutter/wiki/Desktop-shells) on each
platform, including resource bundling and using plugins.

In this example, the platform-specific code lives in `<platform>`. For
instance, the macOS project is in macos. This follows the pattern of
the `android/` and `ios/` directories in a typical Flutter application.
They are designed to serve as early prototypes of what eventual
`flutter create` for desktop would create, and will be evolving over time
to better reflect that goal.

If you are planning to use Flutter in a project that you maintain manually,
this example application should be treated as a starting point, rather than an
authoritative example. For instance, you might use a different build system,
package resources differently, etc. If you are are adding Flutter to an
existing desktop application, you might instead put the Flutter application code
inside your existing project structure.

The example also serves as a simple test environment for the plugins that are
part of this project, so is a collection of unrelated functionality rather than
a usable application.

(**Note:** You may be tempted to pre-build a generic binary based on this
example that can run any Flutter app. If you do, keep in mind that you *must*
use the same version of Flutter to build `flutter_assets` as you use to build
the runner. If you later upgrade Flutter, or if you distribute the binary
version to other people building their applications with different versions of
Flutter, it *will* break.)

## Building and Running the Example

There is currently no tool that abstracts the platform-specific builds the
way `flutter build` or `flutter run` does for iOS and Android, so you will need
to follow the platform-specific build instructions for your platform below.

The examples build the plugins from source, so you will need to ensure you
have all the dependencies for
[building the plugins on your platform](../plugins/README.md) before continuing.

### Linux

Run `make -C example/linux/`. The example binary and its resources will be
in `example/build/linux`, and can be run from there:

```
$ ./example/build/linux/debug/flutter_embedder_example
```

To build a version with Dart asserts disabled (and thus no DEBUG banner),
run `make BUILD=release` instead, then launch it with:

```
$ ./example/build/linux/release/flutter_embedder_example
```

### macOS

Open the Runner Xcode project under `macos/`, and build and run the
example application target.

### Windows

Open the `Runner` Visual Studio solution file under `windows\` to build and run
the Runner project.

The resulting binary will be in
`example\build\windows\x64\$(Configuration)\Runner\`. It can be run
manually from there. E.g.:

```
> .\"example\build\windows\x64\Debug\Runner\Flutter Desktop Example.exe"
```

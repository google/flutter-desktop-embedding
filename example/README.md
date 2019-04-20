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

The examples build the plugins from source, so you will need to ensure you
have all the dependencies for
[building the plugins on your platform](../plugins/README.md) before continuing.

Also, ensure that you are on a recent version of the [Flutter master
channel](https://github.com/flutter/flutter/wiki/Flutter-build-release-channels).

### Enable Desktop Support

The desktop support in the `flutter` tool is still highly experimental, and
must be enabled with an environment variable. Run the command below in the
terminal/console you will be using to build and run the example.

On macOS or Linux:

```
export ENABLE_FLUTTER_DESKTOP=true
```

On Windows:

```
$env:ENABLE_FLUTTER_DESKTOP="true"
```

### Build and Run

You can now run using the `flutter` tool as you would for mobile. In the
'example' directory, run:

```
flutter run
```

or

```
flutter run --release
```

**Note:** There is still no `flutter create` support for for desktop;
this works only in a project that has already been configured manually for
desktop builds. See [the quick-start guide](../Quick-Start.md) for details.

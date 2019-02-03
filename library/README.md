# Flutter Desktop Embedding Library

This library provides the basic functionality for embedding Flutter into a
desktop application.

This README assumes you have already read [the top level README](../README.md),
which contains important information and setup common to all platforms.

## How to Use This Code

Currently the development workflow assumes you are starting with an existing
desktop application project, and provides the pieces to add Flutter support.
This is very different from the Flutter model, where the native application
projects are created automatically by tools. This may change in the future, but
for now there is no equivalent to `flutter create`.

There are currently no binary releases of the libraries. While a more
Flutter-like model of using an SDK containing pre-compiled binaries is likely
to be supported in the future, for now you must build the library from source.
(**Note:** You may be tempted to pre-build a generic binary that can run any
Flutter app. If you do, keep in mind that the primary reason there are no
binary releases is that you *must* use the same version of Flutter to build
`flutter_assets` as you use to build the library. If you later upgrade Flutter,
or if you distribute the binary version to other people building their
applications with different versions of Flutter, it will break.)

Once you build the library for your platform, link it into your build using
whatever build system you are using, and add the relevant headers (see
platform-specific notes below) to your project's search path.

On all platforms your application will need to bundle your Flutter assets
(as created by `tools/build_flutter_assets`), the built embedding library for
your platform, the Flutter engine library (see platform-specific notes), and
the ICU data from the Flutter engine.

### Linux

#### Dependencies

First you will need to install the relevant library dependencies:
*   GLFW3
*   GTK 3
*   jsoncpp
*   epoxy
*   X11 development libs
*   pkg-config

Installation example for debian-based systems:

```
$ sudo apt-get install libglfw3-dev libepoxy-dev libjsoncpp-dev libgtk-3-dev \
      libx11-dev pkg-config
```

You will need to install the build tools if you don't already have them:
* [ninja](https://github.com/ninja-build/ninja/wiki/Pre-built-Ninja-packages)
* [gn](https://gn.googlesource.com/gn/)

Ensure that both binaries are in your path.

#### Using the Library

To build the library, run the following at the root of this repository:

```
$ tools/gn_dart gen out
$ ninja -C out flutter_embedder
```
Subsequent builds only require the `ninja` step, as the build will automatically
re-run GN generation if necessary.

The build results will be in the top-level `out/` directory. You will need to
link `libflutter_embedder.so` and `libflutter_engine.so` into your binary.
Public headers will be in `out/include/`; you should point dependent
builds at that location rather than the `include/` directories in the
source tree.

See
[flutter_window_controller.h](include/flutter_desktop_embedding/glfw/flutter_window_controller.h)
for details on calling into the library.

### macOS

#### Dependencies

You must have a current version of [Xcode](https://developer.apple.com/xcode/)
installed.

#### Using the Framework

Build the Xcode project under `macos/`, then link the resulting framework
into your application. See [FLEView.h](macos/FLEView.h) and
[FLEViewController.h](macos/FLEViewController.h)
for details on how to use them.

The framework includes the macOS Flutter engine (FlutterEmbedder.framework),
so you do not need to include that framework in your project directly.

*Note*: The framework names are somewhat confusing:
* FlutterEmbedder.framework is the Flutter engine packaged as a framework for
  consumption via the embedding API. This comes from the
  [Flutter project](https://github.com/flutter/flutter).
* FlutterEmbedderMac.framework is the output of this project. It wraps
  FlutterEmbedder and implements the embedding API.

### Windows

#### Dependencies

You must have a copy of Visual Studio installed, and the command line build
tools, such as `vcvars64.bat`, must be in your path. They are found under:

```
<Visual Studio Install Path>\2017\<Version>\VC\Auxiliary\Build
```

e.g.:

```
C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build
```

#### Using the Library

Build the GLFW Library project under `windows/` in Visual Studio into a static
or dynamic library, then link `flutter_embedder.lib` into your binary and make
sure `flutter_window_controller.h` is in your include paths. Also ensure that
the `flutter_engine.dll`, and if using a dynamic library
`flutter_embedder.dll`, are in valid DLL include paths.

The output files are located in `bin\x64\$(Configuration)\GLFW Library\`.

_Note: There is also a [GN build](GN.md) available as an alternative._

## Caveats

* There is currently no versioning system for coordinating the version
  of this project with the required version of Flutter. In the future there will
  be, but for now the expectation is that anyone experimenting with this project
  will be tracking Flutter's master branch. If you encounter build issues, try
  using a newer version of Flutter. If your issues are specific to the latest
  Flutter master, please file a bug!

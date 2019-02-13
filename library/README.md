# Flutter Desktop Embedding Library

This library provides the basic functionality for embedding Flutter into a
desktop application.

This README assumes you have already read [the top level README](../README.md),
which contains important information and setup common to all platforms.

_Note: The library code in this repository is in the process of being migrated
to the `flutter/engine` repository, where it will be available as prebuilt
libraries for each platform. Most of the instructions below will be obsolete
soon._

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

##### Libraries

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

The shared library provides a minimal C interface, but the recommended
approach is to add the code in `out/fde_cpp_library/` to your project, to
interact with the library using richer APIs. See
[flutter_window_controller.h](/library/common/client_wrapper/include/flutter_desktop_embedding/glfw/flutter_window_controller.h)
and the other headers under that directory for details.

### macOS

The macOS library code is now part of Flutter itself, and is available as
a prebuilt `FlutterMacOS.framework`. See the example for an example of
downloading and linking to the framework.

### Windows

#### Dependencies

##### Visual Studio Command Line

The Visual Studio command line build tools, such as `vcvars64.bat`, must be in
your path. They are found under:

```
<Visual Studio Install Path>\2017\<Version>\VC\Auxiliary\Build
```

e.g.:

```
C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build
```

##### jsoncpp

jsoncpp must be downloaded to `third_party/jsoncpp\src`. You can use
`tools/dart_tools/bin/fetch_jsoncpp.dart` to simplify this:

```
> tools\run_dart_tool.bat fetch_jsoncpp third_party\jsoncpp\src
```

#### Using the Library

To build the library, run the following at the root of this repository:

```
$ tools\gn_dart gen out
$ ninja -C out flutter_embedder
```
Subsequent builds only require the `ninja` step, as the build will automatically
re-run GN generation if necessary.

The build results will be in the top-level `out\` directory. You will need to
link `libflutter_embedder.dll` and `libflutter_engine.dll` into your binary.
Public headers will be in `out/include/`; you should point dependent
builds at that location rather than the `include/` directories in the
source tree.

The DLL provides a minimal C interface, but the recommended
approach is to add the code in `out\fde_cpp_library\` to your project, to
interact with the library using richer APIs. See
[flutter_window_controller.h](/library/common/client_wrapper/include/flutter_desktop_embedding/glfw/flutter_window_controller.h)
and the other headers under that directory for details.

## Caveats

* There is currently no versioning system for coordinating the version
  of this project with the required version of Flutter. In the future there will
  be, but for now the expectation is that anyone experimenting with this project
  will be tracking Flutter's master branch. If you encounter build issues, try
  using a newer version of Flutter. If your issues are specific to the latest
  Flutter master, please file a bug!

# Desktop Embedding for Flutter

This purpose of this project is to support building
applications that use [Flutter](https://github.com/flutter/flutter)
on Windows, macOS, and Linux.

It consists of libraries that implement [Flutter's embedding
API](https://github.com/flutter/engine/wiki/Custom-Flutter-Engine-Embedders),
handling drawing and mouse/keyboard input, as well as
optional plugins to access other native platform functionality.

## How to Use This Code

### Setting Up

The tooling and build infrastructure for this project requires that you have
a Flutter tree in the same parent directory as the clone of this project:

```
<parent dir>
  ├─ flutter (from http://github.com/flutter/flutter)
  └─ flutter-desktop-embedding (from https://github.com/google/flutter-desktop-embedding)
```

Alternately, you can place a `.flutter_location_config` file in the directory
containing flutter-desktop-embedding, containing a path to the Flutter tree to
use, if you prefer not to have the Flutter tree next to
flutter-desktop-emebbing.

### Repository Structure

The `library` directory contains the core embedding library code. See the
[README](library/README.md) there for information on building and using it.

The `example` directory contains an example application built using the library
for each platform. If you just want to see something running, or want to see
an example of how to use the library, start there.

In addition, there is:
* `plugins`: Plugins which provide access to additional platform functionality.
  These follow a similar structure to [Flutter
  plugins](https://flutter.io/developing-packages/). See the
  [README](plugins/README.md) for details.
* `third_party`: Dependencies used by this repository, beyond Flutter itself.
* `tools`: Tools used in the development process. Currently these are used
  by the build systems, but in the future developer utilities providing
  some functionality similar to the `flutter` tool may be added.

## Flutter Application

### Requirements

Since desktop is not a supported platform for Flutter, be sure to read the
[Flutter application requirements document](Flutter-Requirements.md) for
important information about how to set up your Flutter application for use
with this library.

### Debugging

Debugging of the Flutter side of a desktop application is possible, but requires
[a modified workflow](Debugging.md).

## Feedback and Discussion

For bug reports and specific feature requests, you can file GitHub issues. For
general discussion and questions there's a [project mailing
list](https://groups.google.com/forum/#!forum/flutter-desktop-embedding-dev).

When submitting issues related to build errors or other bugs, please make sure
to include the git hash of the Flutter checkout you are using. This will help
speed up the debugging process.

## Caveats

* This is not an officially supported Google product.
* This is an exploratory effort, and is not part of the Flutter project. See the
  [Flutter FAQ](https://flutter.io/faq/#can-i-use-flutter-to-build-desktop-apps)
  for Flutter's official stance on desktop development.
* Many features that would be useful for desktop development do not exist yet.
  Check the `plugins` directory for support for native features beyond drawing
  and event processing. If the feature you need isn't there, file a feature
  request, or [write a plugin](plugins/README.md#writing-your-own-plugins)!
* The Linux and Windows implementations currently use GLFW. This is not going
  to be the final implementation for either platform.
* Plugins and text input do not yet work on Windows.

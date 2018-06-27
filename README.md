# Desktop Embedding for Flutter

This repository contains code that implements basic embedders for
[Flutter](https://github.com/flutter/flutter) on desktop platforms, as starting
points for building native desktop applications that embed Flutter.
Currently macOS and Linux are supported, and the goal is to support Windows
in the future as well.

It contains shared libraries that implement [Flutter's embedding
API](https://github.com/flutter/engine/wiki/Custom-Flutter-Engine-Embedders),
handling drawing, mouse event handling, and keyboard support. It also
includes optional plugins to access other native platform functionality.

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
containing flutter-desktop-embedding, containng a path to the Flutter tree to
use, if you prefer not to have the Flutter tree next to
flutter-desktop-emebbing.

### Repository Structure

Each supported platform has a top-level directory named for the platform.
Within that directory is a `library` directory containing the core embedding
library, and an `example` directory containing an example application using it.

See the `README` file in the directory corresponding to your platform for more
details.

In addition, there is:
* `example_flutter`: The Flutter application loaded by the example application
  provided for each platform.
* `plugins`: Plugins which provide access to additional platform functionality.
  These follow a similar structure to [Flutter
  plugins](https://flutter.io/developing-packages/). See the
  [README](plugins/README.md) for details.
* `third_party`: Dependencies used by this repository, beyond Flutter itself.
* `tools`: Tools used in the development process. Currently these are used
  by the build systems, but in the future developer utilities providing
  some functionality similar to the `flutter` tool may be added.

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
* Currently the development workflow assumes you are starting from an existing
  native application shell, and provides the pieces to add Flutter support. This
  is very different from the Flutter model, where the native application
  projects are created automatically. This may change in the future, but for now
  there is no equivalent to `flutter create`.
* Many features that would be useful for desktop development do not exist yet.
  Check the `plugins` directory for support for native features beyond drawing
  and event processing. If the feature you need isn't there, file a feature
  request, or [write a plugin](plugins/README.md#writing-your-own-plugins)!

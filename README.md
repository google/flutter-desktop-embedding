# Desktop Embedding for Flutter

This repository contains code that implements basic embedders for
[Flutter](https://github.com/flutter/flutter) on desktop platforms, as starting
points for building native desktop applications that embed Flutter. It does not
contain the Flutter engine itself, as that is part of the Flutter project, only
implementation of Flutter's embedding API (e.g., passing mouse and keyboard
events to Flutter).

Currently macOS and Linux are supported, and the goal is to support Windows
in the future as well.

## How to use this code

See the README file in the directory corresponding to your platform.

## Discussion

For bug reports and specific feature requests, you can file GitHub issues. For
general discussion and questions there's a [project mailing
list](https://groups.google.com/forum/#!forum/flutter-desktop-embedding-dev).

When submitting issues related to build errors or other bugs, please make sure
to include the git hash of the `Flutter` checkout you are using, as well as the
git hash of the `Flutter Engine` checkout you are using. This will help speed up
the debugging process.

Example:

```
Flutter Version: abcdefg123456
Flutter Engine:  2345678qwertyu
```

## Caveats

This is not an officially supported Google product.

This is an exploratory effort, and is not part of the Flutter project. See the
[Flutter FAQ](https://flutter.io/faq/#can-i-use-flutter-to-build-desktop-apps)
for Flutter's official stance on desktop development.

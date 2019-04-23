# Quick Start

Since `flutter create` is not yet supported for desktop, the easiest way to
try out desktop support with an existing Flutter application is to start
from the `example` application in this project. Two different approaches
for doing that are described below.

With either approach, be sure to read the [Flutter page on desktop
support](https://github.com/flutter/flutter/wiki/Desktop-shells), especially
the section on [changes you are likely to need to make to your Flutter
application](https://github.com/flutter/flutter/wiki/Desktop-shells#flutter-application-requirements).

## Replace the 'example' Flutter Code

Since `example/` is already configured to run on all the platforms this project
supports, you can swap in your project's Dart code, `pubspec.yaml`, resources,
etc., then follow the [normal directions](example/README.md) for building the
example application on your platform.

This will be the easiest approach to keep working as the project changes, but
requires that you essentially wrap your whole application in a
flutter-desktop-embedding checkout.

## Copy the 'linux', 'macos', and/or 'windows' Directories from 'example'

These directories are self-contained, and can be copied to an existing
Flutter project. That will allow `flutter run` to work for desktop targets
(following the [instructions for the example](example/README.md)).

**Be aware that neither the API surface of the Flutter library nor the interaction
between the `flutter` tool and the platform directories is stable,
and no attempt will be made to provide supported migration paths as things
change.** If you use this approach, you should expect that every time you
update Flutter you may have to delete your copies of the platform
directories and re-copy them from an updated version of flutter-desktop-embedding.

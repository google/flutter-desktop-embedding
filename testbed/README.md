# Testbed Application

This application is intended as a tool for developing and testing
the [desktop
libraries](https://github.com/flutter/flutter/wiki/Desktop-shells), as well
as the plugins that are part of this repository.

This application is only likely to be useful if:
* you are working on the Flutter desktop libraries themselves, and want to test
  something,
* you are porting one of this repository's plugins to a new platform, or
* you are looking for an example of how to use plugins on Windows or Linux
  before the `flutter` tooling for plugins is available on those platforms.

Otherwise, you probably want the [example](../example/) instead.

Since it serves as simple test environment for the plugins that are part of
this project, and some desktop-specific Flutter functionality, it is a
collection of unrelated functionality rather than a usable application.

## Setting Up

This application uses all of the plugins in this repository, so make sure you
have all the dependencies for
[building the plugins on your platform](../plugins/README.md).

### Linux

You will also need the X11 headers. For debian-based systems:
```
$ sudo apt-get install libx11-dev
```

## Building and Running

Just `flutter run`, as with `example`.

During `testbed` development it may be useful to run the native build directly
(e.g., building from within Visual Studio). The first build needs to be done
via the `flutter` tool, but after that building the native project directly
works as well.

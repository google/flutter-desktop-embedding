# Testbed Application

This application is intended as a tool for developing and testing
the [desktop
libraries](https://github.com/flutter/flutter/wiki/Desktop-shells), as well
as the plugins that are part of this repository.

This application is only likely to be useful if:
* you want to see an example of using one of the plugins here, or
* you are porting one of those plugins to a new platform, or
* you are working on the Flutter desktop libraries themselves, and want to test
  something.

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

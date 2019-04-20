# Testbed Application

This application is intended as a useful tool for developing and testing
the [desktop
libraries](https://github.com/flutter/flutter/wiki/Desktop-shells), as well
as the plugins that are part of this repository.

If you aren't working on the libraries themselves, this application is
unlikely to be useful to you; see the [exmaple](../example/) instead.

This follows the same general structure as the exmaple app. However,
because it is for development use, it depends on scripts from
[tools](../tools/) that make it easy to use a local engine, rather than
simple calls to `flutter` commands. Most projects would have no need for
the scripts used here.

Since it serves as simple test environment for the plugins that are part of
this project, and some desktop-specific Flutter functionality, it is a
collection of unrelated functionality rather than a usable application.

## Building and Running

The examples build the plugins from source, so you will need to ensure you
have all the dependencies for
[building the plugins on your platform](../plugins/README.md).

Otherwise, other than the exact paths and project names, the instructions
are the same as for the [example application](../example/README.md).

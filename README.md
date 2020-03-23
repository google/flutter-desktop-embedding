# Desktop Embedding for Flutter

This project was originally created to develop Windows, macOS, and Linux
embeddings of [Flutter](https://github.com/flutter/flutter). That work has
since become part of Flutter, and all that remains here are experimental,
early-stage desktop
[plugins](https://flutter.dev/docs/development/packages-and-plugins/developing-packages).

If you just want to start running Flutter on desktop, the place to start is now
[the Flutter wiki](https://github.com/flutter/flutter/wiki/Desktop-shells), rather than this project. You will already need to have followed the
instructions there to get an application running on desktop before using any
of the plugins here.

## Setting Up

This project is closely tied to changes in the Flutter repository, so
you must be on the latest version of the [Flutter master
channel](https://github.com/flutter/flutter/wiki/Flutter-build-release-channels#how-to-change-channels).
You should always update this repository and Flutter at the same time,
as breaking changes for desktop can happen at any time.

## Repository Structure

The `plugins` directory contains all the plugins. See
[its README](plugins/README.md) to get started.

`testbed` is a a simple test application for the plugins above. (The typical
structure of having an example app in each plugin is not used here to avoid
the overhead of updating many applications each time there is a breaking change,
which is still common for desktop.)

## Feedback

For bug reports and feature requests related to the plugins, you can file GitHub
issues. Bugs and feature requests about Flutter on desktop in general should
be filed in the
[Flutter issue tracker](https://github.com/flutter/flutter/issues).

## Caveats

* This is not an officially supported Google product.
* The code here is in early stages, and not intended for production use.

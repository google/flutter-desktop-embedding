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

## Feedback

**Do not file issues about Flutter for desktop here.** Since the
embeddings have all moved to the Flutter project, the place for desktop bugs
and feature requests is now [the Flutter issue
tracker](https://github.com/flutter/flutter/issues).

For bug reports and feature requests **related to the plugins in this repository**,
please file issues here. Before filing a bug, see Supported Versions below.

## Supported Versions

Breaking changes in Flutter for desktop are still relatively common. The plugins here
are not guaranteed to work in anything other than the latest version of the [Flutter master
channel](https://github.com/flutter/flutter/wiki/Flutter-build-release-channels#how-to-change-channels).

## Repository Structure

The `plugins` directory contains all the plugins. See
[its README](plugins/README.md) to get started.

`testbed` is a a simple test application for the plugins above. (The typical
structure of having an example app in each plugin is not used here to avoid
the overhead of updating many applications each time there is a breaking change.)

## Caveats

* This is not an officially supported Google product.

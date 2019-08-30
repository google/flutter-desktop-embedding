# Desktop Embedding for Flutter

This project was originally created to develop Windows, macOS, and Linux
embeddings of [Flutter](https://github.com/flutter/flutter). That work has
since [become part of
Flutter](https://github.com/flutter/flutter/wiki/Desktop-shells), and this
project is now just an example of, and test environment for, building
applications using those libraries in their current state. It also
includes some experimental, early stage desktop plugins.

As explained in the link above, desktop libraries are still in early stages.
**The code here is not stable, nor intended for production use.**

## Setting Up

This project is closely tied to changes in the Flutter repository, so
you must be on the latest version of the [Flutter master
channel](https://github.com/flutter/flutter/wiki/Flutter-build-release-channels#how-to-change-channels).
You should always update this repository and Flutter at the same time,
as breaking changes for desktop happen frequently.

### Tools

First you will need to [enable Flutter desktop support for your
platform](https://github.com/flutter/flutter/wiki/Desktop-shells#tooling).

Then run `flutter doctor` and be sure that no issues are reported for the
sections relevant to your platform.

## Running a Project

### Example

Once you have everything set up, just `flutter run` in the `example` directory
to run your first desktop Flutter application!

Note: Only `debug` mode is currently available for Windows and Linux. Running with
`--release` or `--profile` will succeed, but the result will still be using a
`debug` Flutter configuration: asserts will fire, the observatory will be enabled,
etc.

### Running Other Flutter Projects

See [the example README](example/README.md) for information on using the
example as a starting point to run another project.

## Repository Structure

`testbed` is a more complex example that is primarily intended for people
actively working on Flutter for desktop. See [its README](testbed/README.md)
for details.

The `plugins` directory has early-stage desktop
[plugins](https://flutter.dev/docs/development/packages-and-plugins/developing-packages).
See the [README](plugins/README.md) for details.

## Feedback and Discussion

For bug reports and feature requests specific to the example or the plugins,
you can file GitHub issues. Bugs and feature requests related to desktop support
in general should be filed in the
[Flutter issue tracker](https://github.com/flutter/flutter/issues).

For general discussion and questions there's a [project mailing
list](https://groups.google.com/forum/#!forum/flutter-desktop-embedding-dev).

## Caveats

* This is not an officially supported Google product.
* The code and examples here, and the desktop Flutter libraries they use, are
  in early stages, and not intended for production use.

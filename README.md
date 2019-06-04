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

Everything in this project requires [enabling desktop support in
Flutter](https://github.com/flutter/flutter/wiki/Desktop-shells#tooling):
* Ensure that you are on the latest version of the [Flutter master
  channel](https://github.com/flutter/flutter/wiki/Flutter-build-release-channels#how-to-change-channels).
  * You should always update this repository and Flutter at the same time,
    as breaking changes for desktop happen frequently.
* Set the environment variable to enable desktop in the terminal you will be
  using:
  * macOS/Linux: `export ENABLE_FLUTTER_DESKTOP=true`
  * Windows: `$env:ENABLE_FLUTTER_DESKTOP="true"` (PowerShell) or
    `set ENABLE_FLUTTER_DESKTOP=true` (CMD).

### Tools

Run `flutter doctor` and be sure that no issues are reported for the sections
relevant to your platform.

`doctor` support for Windows and Linux is coming soon; in the meantime the
requirements are:
* Linux: Make, and a recent version of clang.
* Windows: Visual Studio 2017 or 2019, including the "Desktop development with
  C++" workload.

## Running a Project

### Example

Once you have everything set up, just `flutter run` in the `example` directory
to run your first desktop Flutter application!

Note: Only `debug` mode is currently available. Running with `--release` will
succeed, but the result will still be using a `debug` Flutter configuration:
asserts will fire, the observatory will be enabled, etc.

### Running Other Flutter Projects

See [the example README](example/README.md) for information on using the
example as a starting point to run another project.

### IDEs

If you want to use an IDE to run a Flutter project on desktop, you will need
`ENABLE_FLUTTER_DESKTOP` to be set for the IDE:
* VS Code: Add the flag to [dart.env](https://dartcode.org/docs/settings/#dartenv)
  in the VS Code `settings.json`:
  ```
  "dart.env": {
      "ENABLE_FLUTTER_DESKTOP": true,
  }
  ```
  * You can also attach to a desktop Flutter application launched some other way
    using the `Debug: Attach to Flutter Process` command and copying in the
    Observatory URI that was logged on launch.
* IntelliJ/Android Studio: You will need to set the environment for the
  application using the normal process for your OS (e.g., launching it from a
  terminal with the environment variable set may work). You will know the
  variable is correctly set if the devices menu lists your machine as a device.

## Repository Structure

`testbed` is a more complex example that is primarily intended for people
actively working on Flutter for desktop. See [its README](testbed/README.md)
for details.

The `plugins` directory has early-stage desktop
[plugins](https://flutter.dev/docs/development/packages-and-plugins/developing-packages). See the [README](plugins/README.md) for details.

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

# Desktop Plugins

See [the Flutter desktop
page](https://github.com/flutter/flutter/wiki/Desktop-shells#plugins)
for an overview of the current state of plugin development on desktop.

This directory contains three types of plugins:
* `example_plugin`, which like `example/` will eventually be replaced by
  `flutter create -t plugin` support for desktop.
* `flutter_plugins`, which contain Windows and Linux implementations of plugins
  from [the flutter/plugins repository](https://github.com/flutter/plugins)
  that are expected to move to that repository once the plugin APIs are
  sufficiently stable.
* Plugins that prototype functionality that will likely become part of
  Flutter itself.

## Using Plugins

Since the plugins in this repository are not intended to live here long term,
and the `flutter` tool doesn't have plugin support on all platforms yet, these
plugins are not published on pub.dev like normal Flutter plugins. Instead, you
should include them directly from this repository.

An overview of the approach for each platform is below. See the `testbed`
application for an example of including optional plugins, including the changes
to each platform's runner in the corresponding platform directory.

### Dart

Add local package references for the plugins you want to use to your
pubspec.yaml. For example:

```
dependencies:
  ...
  example_plugin:
    path: relative/path/to/plugins/example_plugin
```

(On macOS, you can use a [git
reference](https://dart.dev/tools/pub/dependencies#git-packages)
instead of referencing a local copy.)

Then import it in your dart code as you would any other package:
```dart
import 'package:example_plugin/example_plugin.dart';
```

This step does not apply to `flutter_plugins` plugins, as the
Dart code for those plugins comes from the official plugin.

### macOS

The `flutter` tool now supports macOS plugins. Once the plugin is added to
your pubspec.yaml, `flutter run` will automatically manage the platform side
using CocoaPods (as with iOS plugins).

### Linux

#### Dependencies

The Linux plugins in this project require the following libraries:

* GTK 3
* pkg-config

Installation example for debian-based systems:

```
$ sudo apt-get install libgtk-3-dev pkg-config
```

#### Adding to your Application

The `flutter` tool will generate a plugin registrant for you, so you
won't need to change any C++ code.

Adding it to the build system is still entirely manual, and currently
quite complicated. Run:
```
$ diff u example/linux/Makefile testbed/linux/Makefile
```
to see what kinds of changes are necessary to the Makefile, and adapt based
on the plugins you are using. There may be change to simplify this process
in the short-to-medium term while a full solution is decided on.

**Note:** The eventual implementation of plugin management for Linux will
likely be entirely different from this approach.

#### Building Manually

*This is relevant only if you are using the plugins without doing the above,
for example in manual add-to-app experimentation.*

Run `make -C linux` in the directory of the plugin you want to build.

### Windows

#### Adding to your Application

The `flutter` tool will generate a plugin registrant for you, so you
won't need to change any C++ code.

Adding it to the build system is currently a manual process. To add a plugin:
- Open your application's `Runner.sln` in Visual Studio
- Go to `File` > `Add` > `Existing Project...`
- Add the `.vcxproj` for the plugin
- Go to `Project` > `Project Dependencies...`
  - Make `Runner` depend on the plugin project
  - Make the plugin project depend on `Flutter Build`
- Edit `FlutterPlugins.props` to list the plugin library as a dependency.
  See [`testbed`'s copy](https://github.com/google/flutter-desktop-embedding/blob/master/testbed/windows/FlutterPlugins.props)
  for an example.

Note: The eventual implementation of plugin management for Windows will likely
be entirely different from this approach.

#### Building Manually

*This is relevant only if you are using the plugins without doing the above,
for example in manual add-to-app experimentation.*

The plugin projects are designed to be built from within the solution of
the application using them. Add the `.vcxproj` files for the plugins you want
to build to your application's `.sln`. (Opening a plugin project directly
and trying to build it **will not work** with the current structure.)

The plugin builds in this project put the library at the top level of the
Plugins directory in the application's build output, along with their public
headers.

## Writing Your Own Plugins

You can create local packages following the model of the Windows and Linux
plugins here to use in your own projects; in particular, `example_plugin`
is intended to serve as a starting point for new plugins. For macOS,
you should use `flutter create` as usual.

Keep in mind the notes about API stability on the Flutter desktop page
linked above. On platforms where the plugin API is still unstable, or
where `flutter` tool support doesn't exist yet, you should expect to
need to substantially change plugins written now as the APIs evolve.

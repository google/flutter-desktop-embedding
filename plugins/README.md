# Desktop Plugins

See [the Flutter desktop
page](https://github.com/flutter/flutter/wiki/Desktop-shells#plugins)
for an overview of the current state of plugin development on desktop.

This directory contains three types of plugins:
* `example_plugin`, which like `example/` will eventually be replaced by
  `flutter create -t plugin` support for desktop.
* `flutter_plugins`, which contain desktop implementations of plugins
  from [the flutter/plugins repository](https://github.com/flutter/plugins)
  that are expected to move to an official location once the plugin APIs are
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

#### Building

Run `make -C linux` in the directory of the plugin you want to build.

#### Adding to an Application

Link the library files for the plugins you want to include into your binary.
The plugin builds in this project put the library at the top level of the
output directory (set `OUT_DIR` when calling `make` to set the location),
and the public header you will need in the `include/` directory next to it.

Then to register the plugin, after creating your Flutter window controller
call your plugin's registrar function. For instance:

```cpp
  ExamplePluginRegisterWithRegistrar(
      flutter_controller.GetRegistrarForPlugin("ExamplePlugin"));
```

### Windows

#### Building

The plugin projects are designed to be built from within the solution of
the application using them. Add the .vcxproj files for the plugins you want
to build to your application's Runner.sln. (Opening a plugin project directly
and trying to build it **will not work** with the current structure.)

#### Adding to an Application

Link the library files for the plugins you want to include into your exe.
The plugin builds in this project put the library at the top level of the
Plugins directory in the build output, along with their public headers.

Then to register the plugin, after creating your Flutter window controller
call your plugin's registrar function. For instance:

```cpp
  ExamplePluginRegisterWithRegistrar(
      flutter_controller.GetRegistrarForPlugin("ExamplePlugin"));
```

## Writing Your Own Plugins

You can create local packages following the model of plugins here to
use in your own projects. In particular, `example_plugin` is intended to
serve as a starting point for new plugins.

Keep in mind the notes about API stability on the Flutter desktop page
linked above. On platforms where the plugin API is still unstable, or
where `flutter` tool support doesn't exist yet, you should expect to
need to substantially change plugins written now as the APIs evolve.

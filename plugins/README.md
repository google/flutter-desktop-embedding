# Desktop Plugins

These are optional plugins that can be included in an embedder to access OS
functionality.

## How to use this code

In the long term plugins would be managed via pub, as they are with mobile
Flutter plugins. For now, however, they are designed to be included directly
from this repository, and you must manually manage the linking and registration
of plugins in your application (unlike on mobile, where the `flutter` tool
handles that automatically).

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

After creating your Flutter window controller, call your plugin's registrar
function. For instance:

```cpp
  ExamplePluginRegisterWithRegistrar(
      flutter_controller.GetRegistrarForPlugin("ExamplePlugin"));
```

### Windows

#### Building

The plugin projects are designed to be built from within the solution of
the application using them. Add the .vcxproj files for the plugins you want
to build to your application's Runner.sln.

#### Adding to an Application

Link the library files for the plugins you want to include into your exe.
The plugin builds in this project put the library at the top level of the
Plugins directory in the build output, along with their public headers.

After creating your Flutter window controller, call your plugin's registrar
function. For instance:

```cpp
  ExamplePluginRegisterWithRegistrar(
      flutter_controller.GetRegistrarForPlugin("ExamplePlugin"));
```

## Writing your own plugins

You can create local packages following the model of plugins here to
use in your own projects. In particular, `example_plugin` is intended to
serve as a starting point for new plugins, standing in for the current lack
of `flutter create -t plugin` support for desktop.

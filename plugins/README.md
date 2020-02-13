# Desktop Plugins

See [the Flutter desktop
page](https://github.com/flutter/flutter/wiki/Desktop-shells#plugins)
for an overview of the current state of plugin development on desktop.

This directory contains three types of plugins:
* `sample`, which like `example/` will eventually be replaced by
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

Add dependencies for plugins to your `pubspec.yaml`. For unpublished plugins
such as the ones in this repository, you can use a git reference. For example:

```
dependencies:
  ...
  sample:
    git:
      url: git://github.com/google/flutter-desktop-embedding.git
      path: plugins/sample
      ref: INSERT_HASH_HERE
```

Replace `INSERT_HASH_HERE` with the hash of commit you want to pin to,
usually the latest commit to the repository at the time you add the plugin.
(While omitting the `ref` is possible, it is **strongly** discouraged, as
without it any breaking change to the plugin would break your project
without warning.)

Then import it in your dart code as you would any other package:
```dart
import 'package:sample/sample.dart';
```

The import step does not apply to `flutter_plugins` plugins, as the
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

Adding it to the build system is currently a manual process. To add a plugin:
- Open your project's `Makefile`
- Add the plugins you are using to the `PLUGINS` variable near the top
- Add an explicit build rule for each plugin in the Targets section. For
  instance, for the sample plugin:
  ```
  $(OUT_DIR)/libsample_plugin.so: | sample
  ```

Run:
```
$ diff -u example/linux/Makefile testbed/linux/Makefile
```
to see an example of what the changes should look like.

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

Adding it to the build system is partially a manual process. To add a plugin:
- Open your application's `Runner.sln` in Visual Studio
- Go to `File` > `Add` > `Existing Project...`
- Add the `plugin.vcxproj` for the plugin
- Go to `Project` > `Project Dependencies...`
  - Make `Runner` depend on the plugin project
  - Make the plugin project depend on `Flutter Build`

Note: Plugin management for Windows will likely change substantially
as the project evolves.

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

You can create plugin packages following the model of the Windows and Linux
plugins here to use in your own projects. In particular, `sample`
is intended to serve as a starting point for new plugins; see
[its README](sample/README.md) for details. For macOS,
you should use `flutter create` as usual.

Keep in mind the notes about API stability on the Flutter desktop page
linked above. On platforms where the plugin API is still unstable, or
where `flutter` tool support doesn't exist yet, you should expect to
need to substantially change plugins written now as the APIs evolve.

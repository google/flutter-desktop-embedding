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
and the `flutter` tool's plugin support isn't finalized on all platforms yet, these
plugins are not published on pub.dev like normal Flutter plugins. Instead, you
should include them directly from this repository.

### Dart

Add dependencies for plugins to your `pubspec.yaml` as usual. For unpublished
plugins such as the ones in this repository, you can use a git reference. For
example:

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

### Linux

Many of the Linux plugins in this project require the following libraries:

* GTK 3
* pkg-config

Installation example for debian-based systems:

```
$ sudo apt-get install libgtk-3-dev pkg-config
```

## Writing Your Own Plugins

You can create plugin packages following the model of the Windows and Linux
plugins here to use in your own projects. In particular, `sample`
is intended to serve as a starting point for new plugins; see
[its README](sample/README.md) for details. For macOS,
you should use `flutter create` as usual.

Keep in mind the notes about API stability on the Flutter desktop page
linked above. On platforms where the plugin API and `flutter tool` support
is still unstable, you should expect to need to substantially change plugins
written now as the APIs and tool evolve.

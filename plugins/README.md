# Desktop Plugins

See [the Flutter desktop
page](https://github.com/flutter/flutter/wiki/Desktop-shells#plugins)
for an overview of the current state of plugin development on desktop.

This directory contains two types of plugins:
* `flutter_plugins`, which contain Windows and Linux implementations of plugins
  from [the flutter/plugins repository](https://github.com/flutter/plugins).
  They are expected to move to that repository once the plugin APIs for those
  platforms are sufficiently stable.
* Plugins that prototype functionality that will likely become part of
  Flutter itself.

## Using Plugins

Since the plugins in this repository are not intended to live here long term,
and the `flutter` tool's plugin support isn't finalized on all platforms yet,
these plugins are not published on pub.dev like normal Flutter plugins. Instead,
you should include them directly from this repository:

```
dependencies:
  ...
  file_chooser:
    git:
      url: git://github.com/google/flutter-desktop-embedding.git
      path: plugins/file_chooser
      ref: INSERT_HASH_HERE
```

Replace `INSERT_HASH_HERE` with the hash of commit you want to pin to,
usually the latest commit to the repository at the time you add the plugin.
While omitting the `ref` is possible, it is **strongly** discouraged, as
without it any breaking change to the plugin would break your project
without warning.

### Linux

Many of the Linux plugins in this project require the following libraries:

* GTK 3
* pkg-config

Installation example for debian-based systems:

```
$ sudo apt-get install libgtk-3-dev pkg-config
```

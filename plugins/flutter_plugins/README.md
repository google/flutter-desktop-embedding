# Windows and Linux Implementation of flutter/plugins Plugins

Each plugin in this directory corresponds to a
[`flutter/plugins`](https://github.com/flutter/plugins) plugin with the
same name, minus the `_fde` suffix.

These implementations exist here only as a temporary solution to use these
plugins while the plugin APIs on Windows and Linux stabilize enough that
they can move to the official location and be distributed as normal Flutter
plugins. macOS plugin APIs and tooling are stable, so are already hosted
normally rather than here.

## Using These Plugins

For these plugins, the Dart code comes from the official plugin, so you
must include that in your `pubspec.yaml` as well. For instance, to use
url\_launcher on desktop, you would include:

```
dependencies:
  ...
  url_launcher: ^5.4.0
  url_launcher_fde:
    path: relative/path/to/fde/plugins/flutter_plugins/url_launcher_fde
```

Then follow [the main plugin README](../README.md) instructions for
adding the native implementation to your build.

## Contributing

If you are interested in implementing a flutter/plugins plugin for Windows
and/or Linux, please open a PR!

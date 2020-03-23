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
url\_launcher on desktop, you would include both `url_launcher` and
`url_launcher_fde` in your pubspec.yaml (see [the main plugin
README](../README.md) for instructions on adding these plugins to your
`pubspec.yaml`).

Since the Dart code for those plugins comes from the official plugin, you
do not need to add any `import` in the Dart code other than the main
plugin's `import`. For instance, you would just
`import 'package:url_launcher/url_launcher.dart';` to use url\_launcher\_fde.

## Contributing

If you are interested in implementing a flutter/plugins plugin for Windows
and/or Linux, please open a PR!

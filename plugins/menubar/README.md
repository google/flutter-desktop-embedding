# `menubar` plugin

## Description

This plugin expands the supported platforms for the [`PlatformMenuBar`] class in the Flutter framework to Linux and Windows native menu APIs.

In the same way that you can create native menus for macOS, you can now create native menus for Linux or Windows.

This is an alternative to using the Material menu bars that are drawn by Flutter, since, until Flutter supports multi-window drawing, the Material menus are limited to appearing within the main Flutter window.

## Limitations

Because they are drawn by the host OS, and not by Flutter, of course you don't have nearly the control over the visual look that you would have in Flutter. For that, see the [`MenuBar`] and [`createMaterialMenu`] APIs in the Flutter framework.

Many of the platform provided menu items, like the "services" menu, or the "about" menu item are macOS specific, and therefore not available through this plugin.

## Usage

To add support for platform rendered menus to your application, add a dependency in your `pubspec.yaml` file on this `menubar` plugin:

```yaml
dependencies:
  menubar: ^0.3.0
```

Then, use the [`PlatformMenuBar`] APIs in the Flutter framework in the same way as you would for macOS.

[`PlatformMenuBar`]: https://api.flutter.dev/flutter/widgets/PlatformMenuBar-class.html
[`createMaterialMenu`]: https://master-api.flutter.dev/flutter/material/createMaterialMenu.html
[`MenuBar`]: https://master-api.flutter.dev/flutter/material/MenuBar-class.html

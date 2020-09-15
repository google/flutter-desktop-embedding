# menubar

This plugin provides access to a native menubar.

This is a prototype, and in the long term will either be replaced by functionality
within the Flutter framework itself, or a published plugin (likely part of
flutter/plugins). Either way, the API will change significantly.

## Supported Platforms

- [x] macOS
- [x] Windows
- [x] Linux

## Caveats

### macOS

Currently there is no way to interact with existing top-level menus, only add new ones.
E.g., the Window menu cannot be extended from Flutter code.

## Use

See [the plugin README](../README.md) for general instructions on using FDE plugins.

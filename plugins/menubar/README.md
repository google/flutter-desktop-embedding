# menubar

This plugin provides access to a native menubar.

This is a prototype, and in the long term will either be replaced by functionality
within the Flutter framework itself, or a published plugin (likely part of
flutter/plugins). Either way, the API will change significantly.

## Supported Platforms

- [x] macOS
- [ ] [Windows](https://github.com/google/flutter-desktop-embedding/issues/105)
- [x] Linux

## Caveats

### macOS

Currently there is no way to interact with existing top-level menus, only add new ones.
E.g., the Window menu cannot be extended from Flutter code.

### Linux

The menubar [is a standalone window](https://github.com/google/flutter-desktop-embedding/issues/290)
rather than at the top of the window. This implementation exists purely to allow for early
experimentation with native menus on Linux until the full (non-GLFW) Linux embedding is
written.

## Use

See [the plugin README](../README.md) for general instructions on using FDE plugins.

### Linux

You will need to update `main.cc` to include [the GTK initialization and runloop changes
shown in the `testbed`
example](https://github.com/google/flutter-desktop-embedding/blob/master/testbed/linux/main.cc#L81-L91).

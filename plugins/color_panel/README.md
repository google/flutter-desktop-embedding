# color_panel

This plugin provides access to a native color picker.

It exists primarily to serve as an example of using native UI in a desktop plugin,
and may be removed at some point in the future.

## Supported Platforms

- [x] macOS
- [ ] [Windows](https://github.com/google/flutter-desktop-embedding/issues/105)
- [x] Linux

## Use

See [the plugin README](../README.md) for general instructions on using FDE plugins.

### Linux

You will need to update `main.cc` to include [the GTK initialization and runloop changes
shown in the `testbed`
example](https://github.com/google/flutter-desktop-embedding/blob/master/testbed/linux/main.cc#L81-L91).

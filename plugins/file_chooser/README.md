# file_chooser

This plugin provides access to a native file chooser for Open and Save operations.

This is a prototype, and in the long term will either be replaced by functionality
within the Flutter framework itself, or a published plugin (likely part of
flutter/plugins). Either way, the API may change significantly.

## Supported Platforms

- [x] macOS
- [x] Windows
- [x] Linux

## Use

See [the plugin README](../README.md) for general instructions on using FDE plugins.

### macOS

You will need to [add an
entitlement](https://github.com/google/flutter-desktop-embedding/blob/master/macOS-Security.md)
for either read-only access:
```
	<key>com.apple.security.files.user-selected.read-only</key>
	<true/>
```
or read/write access:
```
	<key>com.apple.security.files.user-selected.read-write</key>
	<true/>
```
depending on your use case.

### Linux

You will need to update `main.cc` to include [the GTK initialization and runloop changes
shown in the `testbed`
example](https://github.com/google/flutter-desktop-embedding/blob/master/testbed/linux/main.cc#L81-L91).

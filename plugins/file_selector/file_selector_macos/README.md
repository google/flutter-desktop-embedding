# file_selector_macos

The macOS implementation of [`file_selector`][1].

## Usage

### Import the package

This package has not yet been endorsed, meaning that you need to add `file_selector_macos`
as a dependency in your `pubspec.yaml`. It will be not yet be automatically included in your app
when you depend on `package:file_selector`.

This is what the above means to your `pubspec.yaml`:

```yaml
...
dependencies:
  ...
  file_selector: ^0.7.0
  file_selector_macos: ^0.0.3
  ...
```

### Entitlements

You will need to [add an entitlement][2] for either read-only access:
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

[1]: https://github.com/flutter/plugins/tree/master/packages/file_selector
[2]: https://flutter.dev/desktop#entitlements-and-the-app-sandbox

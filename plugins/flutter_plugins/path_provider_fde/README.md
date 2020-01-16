# path_provider_fde

Prototype desktop implementations of
[path_provider](https://pub.dev/packages/path_provider)

See [the main flutter_plugins README](../README.md) for general information about what
this plugin is and how to use it.

## Supported Platforms

- [x] Windows
- [ ] [Linux](https://github.com/google/flutter-desktop-embedding/issues/105)

## Caveats

### Windows

The paths returned by this plugin may change in the future. Most notably,
`getApplicationSupportDirectory` will likely return a different path in the
future.

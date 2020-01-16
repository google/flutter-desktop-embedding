# url_launcher_fde

Prototype desktop implementations of
[url_launcher](https://pub.dev/packages/url_launcher)

See [the main flutter_plugins README](../README.md) for general information about what
this plugin is and how to use it.

## Supported Platforms

- [x] Windows
- [x] Linux

## Caveats

Only `launch` is implemented, so the common pattern of calling `launch` only if
`canLaunch` returns true will not work.

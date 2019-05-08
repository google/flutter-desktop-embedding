# Running a Locally Built Flutter Engine

It may be useful for debugging or development to run with a [locally built
Flutter engine](https://github.com/flutter/flutter/wiki/Compiling-the-engine).

## Building

### macOS

The `flutter run` workflow for macOS supports `--local-engine`, so just follow
the normal Flutter workflow for using a local engine build.

### Windows and Linux

Work is in progress to add `--local-engine` support for Windows and Linux.
In the meantime, you can get the same effect by adding a file called
`engine_override` at the root of your `flutter_desktop_embedding` checkout
containing the name of your build output directory. For instance on Linux:
```
$ echo host_debug_unopt > engine_override
```

This will cause `sync_flutter_library` to copy your local engine instead of
downloading a prebuilt engine, and `build_flutter_assets` to pass the
`--local-engine` flag when building assets.

Note that this only works for `testbed`, not `example`.

**Important**: Your Flutter engine checkout must be in a folder called `engine`
(as recommended in the [setup
instructions](https://github.com/flutter/flutter/wiki/Setting-up-the-Engine-development-environment)),
which must be next to your `flutter` checkout, or `sync_flutter_library` will
fail.

#### Switching Back to a Prebuilt Engine

To stop using your local engine, just delete `engine_override` and rebuild.
`sync_flutter_library` will automatically re-download the correct prebuilt
engine.

## Dart Changes

If you change any Dart code in your engine, be sure to follow the instructions
[here](https://github.com/flutter/flutter/wiki/Setting-up-the-Engine-development-environment)
or
[here](https://github.com/flutter/flutter/wiki/The-flutter-tool#using-a-locally-built-engine-with-the-flutter-tool)
for temporarily adding a `dependency_overrides` section to your `pubspec.yaml`.

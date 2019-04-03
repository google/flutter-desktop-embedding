# Running a Locally Built Flutter Engine

It may be useful for debugging or development to run with a [locally built
Flutter engine](https://github.com/flutter/flutter/wiki/Compiling-the-engine).
To temporarily override the normal behavior of `sync_flutter_library` and
`build_flutter_assets`, add a file called `engine_override` at the root of
your `flutter_desktop_embedding` checkout. For instance, on macOS or Linux:
```
$ echo host_debug_unopt > engine_override
```

This will cause `sync_flutter_library` to copy your local engine instead of
downloading a prebuilt engine, and `build_flutter_assets` to pass the
`--local-engine` flag when building assets.

**Important**: Your Flutter engine checkout must be in a folder called `engine`
(as recommended in the [setup
instructions](https://github.com/flutter/flutter/wiki/Setting-up-the-Engine-development-environment)),
which must be next to your `flutter` checkout, or `sync_flutter_library` will
fail.

## Dart Changes

If you change any Dart code in your engine, be sure to follow the instructions
[here](https://github.com/flutter/flutter/wiki/Setting-up-the-Engine-development-environment)
or
[here](https://github.com/flutter/flutter/wiki/The-flutter-tool#using-a-locally-built-engine-with-the-flutter-tool)
for adding a `dependency_overrides` section to your `pubspec.yaml`.

## Switching Back to a Prebuilt Engine

To stop using your local engine, just delete `engine_override` (and
`dependency_overrides` if you added them to `pubspec.yaml`) and rebuild.
`sync_flutter_library` will automatically re-download the correct prebuilt
engine.

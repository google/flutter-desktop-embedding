# The Flutter Linux Desktop Embedder

This framework provides the basic functionality for embedding a Flutter app on
the Linux desktop. This currently includes support for:

*  Drawing a Flutter view.
*  Mouse event handling.

# How to Use This Code

Note that the example build here is `host_debug_unopt` (you'll find more info on
what that means in this section). This can be changed to whatever version of
the Flutter Engine you end up building.

First you will need to install the relevant dependencies.

## Dependencies

Requires GLFW3 on your system (example for debian-based systems):

```
$ sudo apt-get install libglfw3-dev
```

Next you will need to follow the steps outlined on the flutter engine's
[contributing](https://github.com/flutter/engine/blob/master/CONTRIBUTING.md)
document so that you can build a copy of `libflutter_engine.so`.

Then copy it in the `linux/library/` directory.

```
$ cp <path_to_flutter_engine>/src/out/host_debug_unopt/libflutter_engine.so \
       <path_to_flutter_desktop_embedding_repo>/linux/library
```

Then copy `embedder.h` into the include directory (the file can be found under
the the flutter engine checkout).

```
$ cp <path_to_flutter_engine>/src/flutter/shell/platform/embedder/embedder.h \
     <path_to_flutter_desktop_embedding_repo>/linux/library/include
```

## Building and Running a Flutter App

There are already [examples](https://flutter.io/get-started/) on building
Flutter apps out there. This assumes you're using the existing example app
contained in the repo.

For this example, you should have a checkout of the flutter repo with the same
parent directory as the `flutter-desktop-embedding` repository, like so:

```
<parent dir>
  ├─ flutter/ (from http://github.com/flutter/flutter)
  └─ flutter-desktop-embedding/ (from https://github.com/google/flutter-desktop-embedding)
```

After that's all done you should be able to run `make` within the `linux`
directory and have access to a `flutter_embedder_example` binary.

```
$ make
```

This should generate all the files necessary to run your application.

## Running the Example Code

Once the directories are setup like above and you've built everything,
the `flutter_embedder_example` code expects to be run from the `linux/`
directory like so:

```
$ ./example/flutter_embedder_example
```

# Caveats

Platform-specific features like a file chooser, menu bar interaction, etc, are
not yet present, but will be added over time.

While GLFW is in use in the current iteration, this is not going to be the final
state for Linux support.

Stay tuned for more documentation.


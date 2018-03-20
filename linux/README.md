# The Flutter Linux Desktop Embedder

This framework provides the basic functionality for embedding a Flutter app on
the Linux desktop. This currently includes support for:

*   Drawing a Flutter view.
*   Mouse event handling.

# How to Use This Code

Note that the example build here is `host_debug_unopt` (you'll find more info on
what that means in this section). This can be changed to whatever version of the
Flutter Engine you end up building.

First you will need to install the relevant dependencies.

## Dependencies

Requires:

*   GLFW3
*   GTK 3
*   jsoncpp
*   epoxy
*   X11 development libs
*   pkg-config

Installation example for debian-based systems:

```
$ sudo apt-get install libglfw3-dev libepoxy-dev libjsoncpp-dev libgtk-3-dev \
      libx11-dev pkg-config
```

Also requires a checkout of the Flutter repo and Flutter Engine repo. For the
most straightforward build make sure to set up all checkouts with the same
parent directory like so:

```
<parent dir>
  ├─ flutter/ (from http://github.com/flutter/flutter)
  ├─ engine/ (from https://github.com/flutter/engine)
  └─ flutter-desktop-embedding/ (from https://github.com/google/flutter-desktop-embedding)
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

This assumes you're using the existing example app contained in the repo.

You should be able to run `make` within the `linux` directory and have access to
a `flutter_embedder_example` binary.

```
$ make
```

This should generate all the files necessary to run the example application.

## Running the Example Code

Once the directories are setup like above and you've built everything, the
`flutter_embedder_example` code expects to be run from the `linux/` directory
like so:

```
$ ./example/flutter_embedder_example
```

# Caveats

Platform-specific features like a file chooser, menu bar interaction, etc, are
not yet present, but will be added over time.

While GLFW is in use in the current iteration, this is not going to be the final
state for Linux support.

Stay tuned for more documentation.

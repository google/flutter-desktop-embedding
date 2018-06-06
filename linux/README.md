# The Flutter Linux Desktop Embedder

This framework provides the basic functionality for embedding a Flutter app on
the Linux desktop. This currently includes support for:

*   Drawing a Flutter view.
*   Mouse event handling.

# How to Use This Code

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

You will also need a checkout of the Flutter repository. The tooling and
build system expect it to be in the same directory as your checkout of
this repository:

```
<parent dir>
  ├─ flutter/ (from http://github.com/flutter/flutter)
  └─ flutter-desktop-embedding/ (from https://github.com/google/flutter-desktop-embedding)
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

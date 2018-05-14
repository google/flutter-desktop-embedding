# The Flutter Linux Desktop Embedder

This framework provides the basic functionality for embedding a Flutter app on
the Linux desktop. This currently includes support for:

*   Drawing a Flutter view.
*   Mouse event handling.
*   Basic ASCII Keyboard input.

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
parent directory like so (note `flutter-engine` is not the default name when
using `git checkout`. Make sure to check it out to the right directory):

```
<parent dir>
  ├─ flutter/ (from http://github.com/flutter/flutter)
  ├─ flutter-engine/ (from https://github.com/flutter/engine)
  └─ flutter-desktop-embedding/ (from https://github.com/google/flutter-desktop-embedding)
```

After you've checked out the engine code, make sure to sync to the version
appropriate for your checkout of Flutter. This can be done using the
`engine.version` file. Here is how you can check out the correct version of the
engine when inside the `engine/` repo.

```
$ git checkout $(cat ../flutter/bin/internal/engine.version)
```

Then you'll need to follow the steps for setting up the prerequisite
tools/binaries (`gclient`, for example)outlined on the engine's
[contributing](https://github.com/flutter/engine/blob/master/CONTRIBUTING.md)
page.

## Building and Running a Flutter App

This assumes you're using the existing example app contained in the repo.

You should be able to run `make` within the `linux` directory and have access to
a `flutter_embedder_example` binary.

```
$ make
```

This should generate all the files necessary to run the example application,
including the flutter engine library.

## Running the Example Code

Once the directories are setup like above and you've built everything, the
`flutter_embedder_example` code expects to be run from the `linux/` directory
like so:

```
$ ./example/flutter_embedder_example
```

## Cleaning up

If you want to clean up generated all generated files, you'll need to run;

```
$ make clean
```

But this will also delete all code for building the engine, which can take a
long time. If you just want to clean the local code (include the example flutter
app), then run the following instead:

```
$ make clean_local
```

# Caveats

Platform-specific features like a file chooser, menu bar interaction, etc, are
not yet present, but will be added over time.

While GLFW is in use in the current iteration, this is not going to be the final
state for Linux support.

Stay tuned for more documentation.

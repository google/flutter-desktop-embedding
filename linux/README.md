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

Then copy it in the `linux/` directory.

```
$ cp <path_to_flutter_engine>/src/out/host_debug_unopt/libflutter_engine.so \
       <path_to_flutter_desktop_embedding_repo>/linux/
```

Then copy `embedder.h` into the same directory (the file can be found on [this
page](https://github.com/flutter/engine/wiki/Custom-Flutter-Engine-Embedders),
under [this
link](https://github.com/flutter/engine/blob/4733e3373789894aa4f593137c6d440891d492a2/shell/platform/embedder/embedder.h), or you can copy it from the flutter engine checkout)

```
$ cp <path_to_flutter_engine>/src/flutter/shell/platform/embedder/embedder.h \
     <path_to_flutter_desktop_embedding_repo>/linux
```

After that's all done you should be able to run `make` and have access to a
`flutter_embedder` binary.

```
$ make
```

After that you'll probably want to run an example Flutter app if you don't
already have one.

## Building and Running a Flutter App

There are already [examples](https://flutter.io/get-started/) on building
Flutter apps out there. This assumes you've already got an example somewhere.

For this you'll need a working `flutter` binary. An easy way to get both the
`flutter` binary and an example app is to clone the [flutter
repo](https://github.com/flutter/flutter), and you can then build, for example,
the demo gallery.

```
$ git clone https://github.com/flutter/flutter.git
$ cd flutter/examples/flutter_gallery
$ ../../bin/flutter build flx
```

This should generate all the files necessary to run your application.

## Running the application

Go back to the `linux/` directory in the repo and you can then run the example
app like so:

```
$ ./flutter_embedder --flutter_app_directory \
        <path_to_flutter_repo>/examples/flutter_gallery \
        --icu_data_path \
        <path_to_flutter_engine>/src/out/host_debug_unopt/icudtl.dat
```

# Caveats

Platform-specific features like a file chooser, menu bar interaction, etc, are
not yet present, but will be added over time.

While GLFW is in use in the current iteration, this is not going to be the final
state for Linux support.

Stay tuned for more documentation.


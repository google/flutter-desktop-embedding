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

Then copy `embedder.h` into the include directory (the file can be found on [this
page](https://github.com/flutter/engine/wiki/Custom-Flutter-Engine-Embedders),
under [this
link](https://github.com/flutter/engine/blob/4733e3373789894aa4f593137c6d440891d492a2/shell/platform/embedder/embedder.h), or you can copy it from the flutter engine checkout)

```
$ cp <path_to_flutter_engine>/src/flutter/shell/platform/embedder/embedder.h \
     <path_to_flutter_desktop_embedding_repo>/linux/library/include
```

After that's all done you should be able to run `make` within the `linux`
directory and have access to a `flutter_embedder_example` binary.

```
$ make
```


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

Note that the `flutter_embedder_example` binary is hard coded with the
assumption that you've checked out the `flutter` source in a common root
directory with this repository, like this:

```
  root_dir> --
              \
              +--- [ flutter/ ]
              |
              +--- [ flutter-desktop-embedding/ ]
```

And have run `flutter build flx` in the `flutter_gallery` example app under
`flutter/examples`.

## Running the Example Code

Once you've built everything, and the directories are setup as outlined above,
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


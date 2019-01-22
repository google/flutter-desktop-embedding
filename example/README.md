# Desktop Flutter Example

This application shows an example of how to use the embedding library on each
platform including build dependencies, resource bundling, and using plugins.

In this example, the platform-specific code lives in `<platform>_fde`. For
instance, the macOS project is in macos\_fde. This follows the pattern of
the `android/` and `ios/` directories in a typical Flutter application (with
`_fde` suffixes to avoid confusion or collisions if desktop support is added
to Flutter itself). There's no requirement to use the same names in your
project, or even to put them in the Flutter application directory.

The example application is intended to be a starting point, rather than an
authoritative example. For instance, you might use a different build system,
package resources differently, etc. If you are are adding Flutter to an
existing desktop application, you might instead put the Flutter application code
inside your existing project structure.

It also serves as a simple test environment for the plugins that are part of
this project, and built-in event handling, so is a collection of unrelated
functionality rather than a usable application.

## Building and Running the Example

There is currently no tool that abstracts the platform-specific builds the
way `flutter build` or `flutter run` does for iOS and Android, so you will need
to follow the platform-specific build instructions for your platform below.

The examples build the library from source, so you will need to ensure you
have all the dependencies for
[building the library on your platform](../library/README.md) before continuing.

### Linux

Run `make -C example/linux_fde/`. The example binary and its resources will be
in `example/build/linux_fde`, and can be run from there:

```
$ ./example/build/linux_fde/debug/flutter_embedder_example
```

To build a version with Dart asserts disabled (and thus no DEBUG banner),
run `make BUILD=release` instead, then launch it with:

```
$ ./example/build/linux_fde/release/flutter_embedder_example
```

### macOS

Open the ExampleEmbedder Xcode project under `macos_fde/`, and build and run the
example application target.

#### Note

Future iterations will likely move away from the use of the XIB file, as it
makes it harder to see the necessary view setup. Most notably, to add an FLEView
to a XIB in your own project:
* Drag in an OpenGL View.
* Change the class to FLEView.
* Check the Double Buffer option. If your view doesn't draw, you have likely
  forgotten this step.
* Check the Supports Hi-Res Backing option. If you only see a portion of
  your application when running on a high-DPI monitor, you have likely
  forgotten this step.

### Windows

Open the `Example Embedder` Visual Studio solution file under `windows_fde\` and
build the GLFW Example project.

The resulting binary will be in `bin\x64\$(Configuration)\GLFW Example\`. It
currently uses relative paths so must be run from the `windows_fde\` directory:

```
> ".\bin\x64\$(Configuration)\GLFW Example\GLFW Example.exe"
```

e.g.:

```
> ".\bin\x64\Debug Dynamic Library\GLFW Example\GLFW Example.exe"
```

Or you can use Visual Studio's inbuilt debugger to build and run the
example application automatically.

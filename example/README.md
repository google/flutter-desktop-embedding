# Desktop Flutter Example

This application shows an example of how to use the embedding library on each
platform including build dependencies, resource bundling, and using plugins.

The example application is intended to be a starting point, rather than an
authoritative example. For instance, you might use a different build system,
package resources differently, etc.

It also serves as a simple test environment for the plugins that are part of
this project, and built-in event handling, so is a collection of unrelated
functionality rather than a usable application.

## Building and Running the Example

Since the exmaple is meant to show how the library would actually be used, it
deliberately uses platform-specific build systems that are separate from the
rest of the project's build system.

The examples do build the library from source, so you will need to ensure you
have all the dependencies for
[building the library on your platform](../library/README.md) before continuing.

### Linux

Run `make` under `linux/`. The example binary and its resources will be
in `out/`, and can be run from there:

```
$ ./out/flutter_embedder_example
```

### macOS

Open the ExampleEmbedder Xcode project under `macos/`, and build and run the
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

Open the `Example Embedder` Visual Studio solution file under `windows\` and
build the GLFW Example project.

The resulting binary will be in `bin\x64\$(Configuration)\GLFW Example\`. It
currently uses relative paths so much be run from the `windows\` directory:

```
> ".\bin\x64\$(Configuration)\GLFW Example\GLFW Example.exe"
```

e.g.:

```
> ".\bin\x64\Debug Dynamic Library\GLFW Example\GLFW Example.exe"
```

Or you can use Visual Studio's inbuilt debugger to build and run the
example application automatically.

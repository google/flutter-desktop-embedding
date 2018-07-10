# The Flutter Windows Desktop Embedder

This framework provides the basic functionality for embedding a Flutter app on
the Windows desktop.

This README assumes you have already read [the top level README](../README.md),
which contains important information and setup common to all platforms.

## Flutter Location

Contrary to [the top level README](../README.md) Windows cannot be run using a
`.flutter_location_config` file and a Flutter tree must be located in the same
parent directory as this repo like so:

```
<parent dir>
  ├─ flutter (from http://github.com/flutter/flutter)
  └─ flutter-desktop-embedding (from https://github.com/google/flutter-desktop-embedding)
```

## Minimum Flutter Version

The minimum version of Flutter supported on Windows is
[32941a8](https://github.com/flutter/flutter/commit/32941a8cc0df5d7653a5c2c40ffb180c4db1c15d).

## Using the Library

Build the GLFW Library project in Visual Studio into a static or dynamic library,
then link `flutter_embedder.lib` and include `embedder.h` into your binary. Also
ensure that the `flutter_engine.dll`, and if using a dynamic library
`flutter_embedder.dll`, are in valid DLL include paths.

The output files are located in `bin\x64\$(Configuration)\GLFW Library\`.

## Example Application

The application under `GLFW Example\` shows an example application using the
library.

You should be able to build the GLFW Example project in Visual Studio and have
access to `GLFW Example.exe` located in `bin\x64\$(Configuration)\GLFW Example\`.

The resulting binary expects to be run from this directory like so:

```
> ".\bin\x64\$(Configuration)\GLFW Example\GLFW Example.exe"
```

e.g:

```
> ".\bin\x64\Debug .dll\GLFW Example\GLFW Example.exe"
```

or you can use Visual Studio's inbuilt debugger to build the library and run the
example application automatically.

## Caveats

While GLFW is in use in the current iteration, this is not going to be the final
state for Windows support.
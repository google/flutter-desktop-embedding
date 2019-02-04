# Using GN

If you are building on Windows, you can use GN instead of Visual Studio.

## Dependencies

### Tools

In addition to the normal dependencies, you will need to install:
* [ninja](https://github.com/ninja-build/ninja/wiki/Pre-built-Ninja-packages)
* [gn](https://gn.googlesource.com/gn/)

Ensure that both binaries are in your path.

### jsoncpp

jsoncpp must be manually downloaded to
`third_party/jsoncpp\src`. Use
`tools/dart_tools/bin/fetch_jsoncpp.dart` to automatically download `jsoncpp`
as shown below:

```
> tools\run_dart_tool.bat fetch_jsoncpp third_party\jsoncpp\src
```

## Building

### Library

To build the library, run the following at the root of this repository:

```
$ tools/gn_dart gen out
$ ninja -C out flutter_embedder
```

The build results will be in the top-level `out/` directory. `out/include/` will
have the public headers for all build libraries, so you can point dependent
builds at that single location rather than the `include/` directories in the
source tree. You will need to set USE\_FLATTENED\_INCLUDES in your build, since
the embedding header library layout is slightly different under `out/include/`.

Subsequent builds only require the `ninja` step, as the build will automatically
re-run GN generation if necessary.

### Plugins

You can build individual plugins by replacing `flutter_embedder` with the name
of the desired plugin target. Alternately, you can build the library and all
supported plugins with:

```
$ ninja -C out
```

### Example

Building the example with GN is not currently supported. Follow the [Visual
Studio example build instructions](../example/README.md) to build the example
app.

## Feedback

If you encounter issues with the GN build, please test with Visual
Studio before filing a bug so that the report can include whether the issue is
specific to GN, or a general build issue.

# Using GN

If you are building on Linux or Windows, you can use GN instead of Make or
Visual Studio.

This is currently optional and is under evaluation, but in the future it may
become the build system used on all platforms.

## Dependencies

In addition to the normal dependencies, you will need to install:
* [ninja](https://github.com/ninja-build/ninja/wiki/Pre-built-Ninja-packages)
* [gn](https://gn.googlesource.com/gn/)

Ensure that both binaries are in your path.

### Windows

Windows also requires the 64 bit compiler, linker and setup scripts to be in
your path. They are found under:

```
> Visual Studio Install Path\2017\Version\VC\Auxiliary\Build
```

e.g.:

```
> C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build
```

Windows requires jsoncpp to be downloaded to
`library/windows/third_party/jsoncpp`. Use
`tools/dart_tools/bin/fetch_jsoncpp.dart` to automatically download `jsoncpp`
as shown below:

```
> tools\run_dart_tool.bat fetch_jsoncpp library\windows\third_party\jsoncpp
```

Currently the GN build rule for `jsoncpp` is a placeholder that will eventually
be replaced with full GN build capabilities. Currently if you modify the source
of `jsoncpp`, `out/gen/JSON` will need to be deleted for GN to rebuild it.

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

#### Linux

To use the GN build for the depedencies of the example application, when
running `make` for the example add `USE_GN=1` to the end of the command.

#### Windows

Building the example with GN is not currently supported. Follow the [Visual
Studio example build instructions](../example/README.md) to build the example
app.

## Feedback

If you encounter issues with the GN build, please test with Make or Visual
Studio before filing a bug so that the report can include whether the issue is
specific to GN, or a general build issue.

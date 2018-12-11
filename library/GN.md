# Using GN

If you are building on Linux, you can use GN instead of Make.

This is currently optional and is under evaluation, but in the future it may
become the build system used on all platforms.

## Dependencies

In addition to the normal dependencies, you will need to install:
* [ninja](https://github.com/ninja-build/ninja/wiki/Pre-built-Ninja-packages)
* [gn](https://gn.googlesource.com/gn/) 

Ensure that both binaries are in your path.

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

To use the GN build for the depedencies of the example application, when
running `make` for the example add `USE_GN=1` to the end of the command.

The resulting binary will be in `out/example/` rather than `example/linux/out/`.

## Feedback

If you encounter issues with the GN build, please test with Make before filing
a bug so that the report can include whether the issue is specific to GN, or
a general build issue.

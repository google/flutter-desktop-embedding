# macOS Embedding for Flutter

This framework provides basic embedding functionality for embedding a
Flutter view into a macOS application.

This README assumes you have already read [the top level README](../README.md),
which contains important information and setup common to all platforms.

## How to Use This Code

### Dependencies

You must have a current version of [Xcode](https://developer.apple.com/xcode/)
installed.

### Using the Framework

Build the Xcode project under `library/`, then link the resulting framework
into your application. See [FLEView.h](library/FLEView.h) and
[FLEViewController.h](library/FLEViewController.h)
for details on how to use them.

The framework includes the macOS Flutter engine (FlutterEmbedder.framework),
so you do not need to include that framework in your project.

*Note*: The framework names are somewhat confusing:
* FlutterEmbedder.framework is the Flutter engine packaged as a framework for
  consumption via the embedding API. This comes from the
  [Flutter project](https://github.com/flutter/flutter).
* FlutterEmbedderMac.framework is the output of this project. It wraps
  FlutterEmbedder and implements the embedding API.

## Example Application

The application under `example/` shows an example application using the
framework, including bundling plugins via project dependencies.

Future iterations will likely move away from the use of the XIB file, as it
makes it harder to see the necessary setup. Most notably, to add an FLEView
to a XIB in your project:
* Drag in an OpenGL View.
* Change the class to FLEView.
* Check the Double Buffer option. If your view doesn't draw, you have likely
  forgotten this step.
* Check the Supports Hi-Res Backing option. If you only see a portion of
  your application when running on a high-DPI monitor, you have likely
  forgotten this step.

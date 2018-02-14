# macOS Embedding for Flutter

This framework provides basic embedding functionality for embedding a
Flutter view into a macOS application:
* Drawing
* Mouse event handling
* Basic text input

## How to use this code

Build the included Xcode project, then link the resulting framework
into your application. See the headers for FLEView and FLEViewController
for details on how to use them.

The framework includes the macOS Flutter engine (FlutterEmbedder.framework),
so you do not need to include that framework in your project.

*Note*: The framework names are somewhat confusing:
* FlutterEmbedder.framework is the Flutter engine packaged as a framework for
  consumption via the embedding API. This comes from the
  [Flutter project](https://github.com/flutter/flutter).
* FlutterEmbedderMac.framework is the output of this project. It wraps
  FlutterEmbedder and implements the embedding API.

Stay tuned for more documentation, and a sample project using the framework.

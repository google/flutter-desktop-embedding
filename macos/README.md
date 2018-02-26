# macOS Embedding for Flutter

This framework provides basic embedding functionality for embedding a
Flutter view into a macOS application:
* Drawing
* Mouse event handling
* Basic text input

## How to use this code

_Note:_ For the below steps to work, the https://github.com/google/flutter-desktop-embedding
repo must be cloned into the same parent directory as the
http://github.com/flutter/flutter repo.

```
<parent dir>
  ├─ flutter/ (from http://github.com/flutter/flutter)
  └─ flutter-desktop-embedding/ (from https://github.com/google/flutter-desktop-embedding)
```

Build the Xcode project under library/, then link the resulting framework
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

## Caveats

Many features that would be useful for desktop development (e.g., the ability to
interact with the menu bar) do not yet exist. More platform plugins that provide
additional functionality will be added over time.

Stay tuned for more documentation, and a sample project using the framework.

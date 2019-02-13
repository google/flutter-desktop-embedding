# Desktop Plugins

These are optional plugins that can be included in an embedder to access OS
functionality.

## How to use this code

In the long term plugins would be managed via pub, as they are with mobile
Flutter plugins. For now, however, they are designed to be included directly
from this repository.

### Flutter

Add local package references for the plugins you want to use to your
pubspec.yaml. For example:

```
dependencies:
  ...
  color_panel:
    path: relative/path/to/plugins/color_panel
```

Then import it in your dart code as you would any other package:
```dart
import 'package:color_panel/color_panel.dart';
```

### macOS

Build the Xcode project under the macos diretory for each plugin you
want to use, then link the resulting framework in your project.

When you set up your FLEViewController, before calling `launchEngine...`,
call `-registerWithRegistrar:` on each plugin you want to use. For
instance:

```objc
  [FLEFileChooserPlugin registerWithRegistrar:
      [myFlutterViewController registrarForPlugin:"FLEFileChooserPlugin"]];
```

### Linux

Run `ninja -C out` at the root of the repository to build all plugins, then
link the libraries for the plugins you want into your application. As with the
library build, `out/` and `out/include/` will contain all the files you need.

After creating your Flutter window controller, call your plugin's registrar
method. For instance:

```cpp
  plugins_color_panel::ColorPanelPlugin::RegisterWithRegistrar(
      my_flutter_controller.GetRegistrarForPlugin(
          "plugins_color_panel::ColorPanelPlugin"));
```

### Example Application

See the example application under each platform's directory in the `example`
directory to see an example of including optional plugins on that platform.

The Flutter application under `example/` shows examples of using
optional plugins on the Dart side.

## Writing your own plugins

You can easily create local packages following the model of plugins here to
use in your own projects. In particular, the color_panel plugin has examples
of typical platform builds for plugins.

If you think they would be generally useful, feel free to submit a pull request
and they could potentially be folded into this repository. In the future, as
noted above, desktop plugins would be managed using a model like mobile
plugins where that wouldn't be necessary.

### Caveats

Currently only JSONMethodCodec is supported for Windows/Linux plugins. See
https://github.com/google/flutter-desktop-embedding/issues/67

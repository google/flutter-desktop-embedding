# Desktop Plugins

These are optional plugins that can be included in an embedder to access OS
functionality.

## How to use this code

In the long term plugins would be managed via pub, as they are with mobile
Flutter plugins. For now, however, they are designed to be included directly
from this repository, and you must manually manage the linking and registration
of plugins in your application (unlike on mobile, where the `flutter` tool
handles that automatically).

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

### Linux/Windows

#### Dependencies

You will need GN and ninja to build the plugins:
* [ninja](https://github.com/ninja-build/ninja/wiki/Pre-built-Ninja-packages)
* [gn](https://gn.googlesource.com/gn/)

Ensure that both binaries are in your path.

##### Linux

The Linux plugins in this project require the following libraries:

* GTK 3
* jsoncpp
* pkg-config

Installation example for debian-based systems:

```
$ sudo apt-get install libgtk-3-dev libjsoncpp-dev pkg-config
```

##### Windows

jsoncpp must be downloaded to `third_party/jsoncpp\src`. You can use
`tools/dart_tools/bin/fetch_jsoncpp.dart` to simplify this:

```
> tools\run_dart_tool.bat fetch_jsoncpp third_party\jsoncpp\src
```

You will also nee the Visual Studio command line build tools, such as
`vcvars64.bat`, in your path for the GN build to work. They are found under:

```
<Visual Studio Install Path>\2017\<Version>\VC\Auxiliary\Build
```

e.g.:

```
C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build
```
 
#### Building

Run the following at the root of this repository to build all plugins:

```
$ tools/gn_dart gen out
$ ninja -C out
```

Subsequent builds only require the ninja step, as the build will automatically re-run GN generation if necessary.

**Note:** If you are using a `.flutter_location_config` file, you will need to run `gn_dart args -C out` to add:
```
flutter_tree_path = "path/to/flutter/tree"
```
with the same path before running `ninja`, as the GN build does not read from the `.flutter_location_config` file.

#### Linking

Link the library files for the plugins you want to include into your binary. `out/` and `out/include/` will contain
all the files you need.

After creating your Flutter window controller, call your plugin's registrar
function. For instance:

```cpp
  ColorPanelRegisterWithRegistrar(
      flutter_controller.GetRegistrarForPlugin("ColorPanel"));
```

### Example Application

See the example application under each platform's directory in the `example`
directory to see an example of including optional plugins on that platform.
(The Windows example does not yet include any plugins, but the registration
process would be the same as for Linux.)

## Writing your own plugins

You can create local packages following the model of plugins here to
use in your own projects. In particular, the color_panel plugin has examples
of typical platform builds for plugins.

### Caveats

Currently only JSONMethodCodec is supported for Windows/Linux plugins. See
https://github.com/google/flutter-desktop-embedding/issues/67

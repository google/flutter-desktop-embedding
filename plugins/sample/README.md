# sample_plugin

This is intended to serve as a starting point for writing your own Windows
and/or Linux plugin, since `flutter create` does not yet support Windows
or Linux.

Before continuing, read [the main plugins README](../README.md) if you haven't already.

## Use

- To create an entirely new plugin, or a federated Windows/Linux implementation
  of an existing plugin, copy the entire `sample_plugin` folder.
  - Update the `pubspec.yaml` as normal for a plugin. Be sure to remove
    `platforms` entries for platforms you aren't supporting.
  - Delete the directories for any platforms you aren't supporting.
- To add desktop support directly to an existing plugin, copy the `windows`
  and/or `linux` directories into that plugin.
  - Update the plugin's `pubspec.yaml` to include the new platforms.
    If you haven't already, you'll need to switch to the new `plugins:`
    format, at the legacy declaration doesn't support desktop.

**WARNING**: The plugin APIs, plugin tooling, and plugin structure for
Windows and Linux **are not at all stable**. Plugins created using this
template are subject to breakage at any time, and will need to be updated
any time any of those things change. This means you **should not publish
Windows or Linux plugins to pub.dev** as anything published now will
almost certainly not work with the final Flutter Windows and Linux support.

### Windows

Basic setup:
- Rename all the `sample*` files to match your plugin's name.
- Change the `FlutterPluginName` in `PluginInfo.props` to your plugin's name.
- Update the header guard (`PLUGINS_SAMPLE_WINDOWS_SAMPLE_PLUGIN_H_`) to
  use your plugin's name.
- Replace all instances of `SamplePlugin` in the `.cpp` and `.h` with your
  plugin's class name. This must match the `windows` entry in your `pubspec.yaml`.
- Replace `sample_plugin` with your plugin's channel name in this call:
  ```
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "sample_plugin",
          &flutter::StandardMethodCodec::GetInstance());
  ```

To implement your plugin logic, update `HandleMethodCall`'s implementation to
handle your plugin's messages instead of `getPlatformVersion`. The plugin
APIs are documented in the headers
[here](https://github.com/flutter/engine/tree/master/shell/platform/common/cpp/client_wrapper/include/flutter)
and
[here](https://github.com/flutter/engine/tree/master/shell/platform/windows/client_wrapper/include/flutter).

### Linux

Basic setup:
- Rename all the `sample_plugin.*` files to match your plugin's name.
- Change the `PLUGIN_NAME` in the `Makefile` to your plugin's name.
- Update the header guard (`PLUGINS_SAMPLE_LINUX_SAMPLE_PLUGIN_H_`) to
  use your plugin's name.
- Replace all instances of `SamplePlugin` in the `.cc` and `.h` with your
  plugin's class name. This must match the `linux` entry in your `pubspec.yaml`.
- Replace `sample_plugin` with your plugin's channel name in this call:
  ```
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "sample_plugin",
          &flutter::StandardMethodCodec::GetInstance());
  ```

To implement your plugin logic, update `HandleMethodCall`'s implementation to
handle your plugin's messages instead of `getPlatformVersion`. The plugin
APIs are documented in the headers
[here](https://github.com/flutter/engine/tree/master/shell/platform/common/cpp/client_wrapper/include/flutter)
and
[here](https://github.com/flutter/engine/tree/master/shell/platform/glfw/client_wrapper/include/flutter).

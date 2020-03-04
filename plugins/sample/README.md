# sample_plugin

This is intended to serve as a starting point for writing your own Windows
and plugin, since `flutter create` does not yet support Windows.

Before continuing, read [the main plugins README](../README.md) if you haven't already.

## Use

- Start with an exisitng Flutter plugin. For a new plugin, use
  `flutter create -t plugin` as usual to create it first.
- Copy the `windows` directory from `sample` into that plugin.
- Update the plugin's `pubspec.yaml` to include `windows` and its
  `pluginClass`.
  - If you haven't already, you'll need to switch to [the new plugin platform declaration
    format](https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms),
    as the legacy declaration doesn't support desktop.

**WARNING**: The plugin APIs, plugin tooling, and plugin structure for
Windows **are not at all stable**. Plugins created using this
sample are subject to breakage at any time, and will need to be updated
any time any of those things change. This means you **should not publish
Windows plugin implementations to pub.dev** as anything published now will
almost certainly not work with the final Flutter Windows support.

### Changes

- Change `sample` in all the filenames to your plugin's name.
- Change the `ProjectName` in `plugin.vcxproj` to your plugin's name.
- Change the `ProjectGuid` in `plugin.vcxproj` to a new, randomly-generated v4
  UUID (all upper case, to avoid issues with Visual Studio). You can use any
  UUID generator that supports v4 for this, such as:
    - Running `New-Guid` in PowerShell
    - Using an online UUID generator
- Change the `FlutterPluginName` in `PluginInfo.props` to your plugin's name.
- Look for comments containing `***` in the `.h` and `.cpp` file, and update
  the code as described in the comment.

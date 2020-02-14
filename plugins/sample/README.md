# sample_plugin

This is intended to serve as a starting point for writing your own Windows
and/or Linux plugin, since `flutter create` does not yet support Windows
or Linux.

Before continuing, read [the main plugins README](../README.md) if you haven't already.

## Use

- To create an entirely new plugin, or a federated Windows/Linux implementation
  of an existing plugin, copy the entire `sample` directory.
  - Update the `pubspec.yaml` as normal for a plugin. Look for comments
    containing `***` and update those entries as described in the comment.
  - Delete the directories for any platforms you aren't supporting.
- To add desktop support directly to an existing plugin, copy the `windows`
  and/or `linux` directories into that plugin.
  - Update the plugin's `pubspec.yaml` to include the new platforms.
    If you haven't already, you'll need to switch to the new `plugins:`
    format, as the legacy declaration doesn't support desktop.

**WARNING**: The plugin APIs, plugin tooling, and plugin structure for
Windows and Linux **are not at all stable**. Plugins created using this
sample are subject to breakage at any time, and will need to be updated
any time any of those things change. This means you **should not publish
Windows or Linux plugins to pub.dev** as anything published now will
almost certainly not work with the final Flutter Windows and Linux support.

### Windows

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

### Linux

- Rename `sample` in all the file names with your plugin's name.
- Change the `PLUGIN_NAME` in the `Makefile` to your plugin's name.
- Look for comments containing `***` in the `.h` and `.cc` file, and update
  the code as described in the comment.

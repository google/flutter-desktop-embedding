# Desktop Plugins

This directory contains plugins that prototype functionality that will likely
either become part of Flutter itself, or become officially supported plugins.

## Using Plugins

Since the plugins in this repository are not intended to live here long term,
these plugins are not published on pub.dev like normal Flutter plugins. Instead,
you should include them directly from this repository:

```
dependencies:
  ...
  file_chooser:
    git:
      url: git://github.com/google/flutter-desktop-embedding.git
      path: plugins/file_chooser
      ref: INSERT_HASH_HERE
```

Replace `INSERT_HASH_HERE` with the hash of commit you want to pin to,
usually the latest commit to the repository at the time you add the plugin.
While omitting the `ref` is possible, it is **strongly** discouraged, as
without it any breaking change to the plugin would break your project
without warning.

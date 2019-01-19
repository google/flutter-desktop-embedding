# Debugging Desktop Flutter Applications

While the current workflow for debugging on desktop is not ideal, it is
possible to do most things, including source-level debugging and hot reload.

Because this relies on workarounds for desktop not being a supported device,
Flutter changes may break the workflows described below. We hope to extend
the `flutter` tool to improve support, but in the meantime please file
bugs in this project if you encounter issues with these instructions.

## Getting the Observatory Port

For all of these approaches, you will need the Observatory port of the
desktop application. Usually, `flutter run` would handle this, but there's
currently no way to `flutter run` a desktop application, so you will need to
provide it manually.

There are two options:

1. **Find the port in the console.** After launching your application, check
   the console output (your terminal in Linux,
   [Console](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/debugging_with_xcode/chapters/debugging_tools.html)
   in Xcode, etc.) for a line like:
   ```
   Observatory listening on http://127.0.0.1:49494/
   ```
   The port in this case is `49494`. This will change on every run of the
   application, so you'll need to repeat this every time you relaunch.

1. **Hard-code the port**. In your embedder code, add `--observatory-port=49494`
   (substituting a port of your choice) to the list of arguments passed to the
   engine. If you are using `example/`, or code based on it, look for the
   line that adds `--disable-dart-asserts` for an example of adding arguments.
   (Be sure not to add the `observatory-port` argument inside the `#if`,
   however.)

## Debugging

### Command Line

The `flutter attach` command can connect to a desktop Flutter application
and provide the same interactive command line that `flutter run` would provide.
In the directory of the Flutter portion of your application (e.g.,
`/example/` for this project's example application) run:

```
$ flutter attach --device-id=flutter-tester --debug-port=49494
```

Use the port you obtained above in place of `49494`. The `device-id` is
necessary to bypass checks for an attached iOS or Android device.

### VS Code

Open the Flutter portion of your application (e.g., `/example/`).
Add a [launch
configuration](https://code.visualstudio.com/docs/editor/debugging#_launch-configurations)
like the following, substituting your Observatory port:

```
  {
    "name": "Flutter Desktop Attach",
    "request": "attach",
    "deviceId": "flutter-tester",
    "observatoryUri": "http://127.0.0.1:49494/",
    "type": "dart"
  }
```

You will likely want to hard-code your observatory port, otherwise you will
need to change `launch.json` every time you relaunch the app.

In addition to the Flutter debug commands, source-level debugging with pause,
continue, variable inspection, etc. should all work.


### IntelliJ

**TBD**. If you test IntelliJ and are able to attach successfully, please
contribute instructions!

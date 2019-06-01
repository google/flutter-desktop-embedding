# Running and Debugging Flutter for Desktop in IDEs

## VS Code

To enable desktop support in Dart Code, add the flag to
[dart.env](https://dartcode.org/docs/settings/#dartenv) in the VS Code
`settings.json`:
```
"dart.env": {
    "ENABLE_FLUTTER_DESKTOP": true,
}
```

### Running

Once desktop support is enabled, you can run and debug using the normal
Dart Code workflow.

### Attaching

Run the `Debug: Attach to Flutter Process` and paste in the Observatory URI logged to
the console when you started your application (look for a line starting with
`Observatory listening on`).

## Android Studio/IntelliJ

### Running

It is not currently possible to set the `ENABLE_FLUTTER_DESKTOP` environment
variable from within IntelliJ. However, if you set it in the environment used to
launch the application (details vary by OS), you should be able to use the normal
run/debug workflow.

### Attaching

**TBD**. It may be possible to create an attach configuration for IntelliJ
using the observatory URI printed to the console. If you test IntelliJ and
are able to attach successfully, please contribute instructions!

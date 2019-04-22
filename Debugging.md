# Debugging Desktop Flutter Applications in IDEs

## VS Code

To enable desktop support in Dart Code, add the flag to
[dart.env](https://dartcode.org/docs/settings/#dartenv) in the VS Code
`settings.json`:
```
"dart.env": {
    "FLUTTER_DESKTOP_EMBEDDING": true,
}
```

You may need to restart VS Code for this change to take effect.

### Running

Once desktop support is enabled, you can run and debug using the normal
Dart Code workflow.

### Attaching

**Attaching from Dart Code is currently broken with Flutter master
due to changes in the Flutter observatory.** Watch [this Dart Code
bug](https://github.com/Dart-Code/Dart-Code/issues/1632) for updates.

## IntelliJ

### Running

It is not currently possible to set the `ENABLE_FLUTTER_DESKTOP` environment
variable in IntelliJ.

### Attaching

**TBD**. It may be possible to create an attach configuration for IntelliJ
using the observatory URI printed to the console. If you test IntelliJ and
are able to attach successfully, please contribute instructions!

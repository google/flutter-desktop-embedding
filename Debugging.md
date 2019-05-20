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

You may need to restart VS Code for this change to take effect.

**Note**: This is not consistently working for everyone; investigation is
in progress, but for now if this doesn't work, use the approach described
under "Android Studio/IntelliJ" below.

### Running

Once desktop support is enabled, you can run and debug using the normal
Dart Code workflow.

### Attaching

Add a [launch
configuration](https://code.visualstudio.com/docs/editor/debugging#_launch-configurations)	
like the following:	


 ```
  {
    "name": "Flutter Desktop Attach",
    "request": "attach",		
    "observatoryUri": "http://127.0.0.1:1234/abcdef123456/",	
    "type": "dart"	
  }	
```

You will need to update the `observatoryUri` every time you re-launch your application
using the logged Observatry URI (look for a line starting with `Observatory listening on`),
as both the port (`1234`) and token (`abcdef123456`) portions will change on every launch.
Be sure to save the file before trying to attach.

In the future, there will hopefully be a simpler workflow that uses a prompt rather than
having to edit the launch configuration every time. Watch [this Dart Code
issue](https://github.com/Dart-Code/Dart-Code/issues/1638) for updates.

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

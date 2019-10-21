# Application Customization

Because `example` is still in the process of being converted to
`flutter create` templates, support for customizing the application
is a work in progres. This page describes the current process for
making common modification to the native application on each platform.

It will be updated as `example` evolves. Keep in mind that as with
everything in this repository, forward-compatibility is not guaranteed;
the process for any customization may change in the future without
warning.

Please file issues for any basic application-level customizations that you would
like to be able to make that aren't listed here.

## macOS

- **Application Name**: Change `PRODUCT_NAME` in
  `macos/Runner/Configs/AppInfo.xcconfig`.
- **Bundle Identifier**: Change `PRODUCT_BUNDLE_IDENTIFIER` in
  `macos/Runner/Configs/AppInfo.xcconfig`.
- **Application Icon**: Replace `macos/Assets.xcassets/app_icon_*` with your
  icon in the appropriate sizes.

## Windows

**Remember that Windows builds are currently debug-only, and should not be
distributed. These instructions are intended for experimentation and feedback
only.**

- **Application Name**: Change `TargetName` in
  `windows\AppConfiguration.props`.
  - You will likely want to change `kFlutterWindowTitle` in
    `windows\window_configuration.cpp` to match. In the future this
    will use the application name automatically by default.
- **Application Icon**: Replace `windows\resources\app_icon.ico` with your
  icon.
  - This will also change the Window icon.

## Linux

**Remember that Linux builds are currently debug-only, and should not be
distributed. These instructions are intended for experimentation and feedback
only.**

Linux has not yet had any customization support added. The fact that these steps
are non-trivial is a known issue.

- **Executable Name**: Change `BINARY_NAME` in `linux/Makefile`.
  - You will likely want to change `window_properties.title` in
    `linux/main.cc` to match. In the future this
    will use the application name automatically by default.
- **Application Icon**: Prepare image data using the method of your choice
  (e.g., by loading from a file in a set location; this may require the use
  of a third-party library depending on the image format) and call `SetIcon`
  on `flutter_controller.window()`. See the `SetIcon` comment in
  `flutter_window.h` for the required format.

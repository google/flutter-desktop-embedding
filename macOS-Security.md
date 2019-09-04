# macOS Signing and Security

macOS builds are now configured by default to be signed, and sandboxed with
App Sandbox.

Managing the sandbox settings is done via the
`macos/Runner-*.entitlements` files. When editing these files, you should not
remove the original `Runner-DebugProfile.entitlements` exceptions (incoming
network connections and JIT), as they are necessary for debug and profile mode
to function correctly.

If you are used to managing entitlement files through the Xcode capabilities UI,
be aware that it appears that the capabilities editor will update only one of
the two files, or in some cases create a whole new entitlements file and switch
the project to use it for all configurations, either of which will cause issues.
The recommended approach is to edit the files directly. Unless you have a very
specific reason, you should always make identical changes to both files.

## App Sandbox Entitlements

If you keep App Sandbox enabled, you will need to manage
[entitlements](https://developer.apple.com/documentation/bundleresources/entitlements/app_sandbox)
for your application if you add certain plugins or other native functionality.
For instance, using the file\_chooser plugin requires adding either the
`com.apple.security.files.user-selected.read-only` or
`com.apple.security.files.user-selected.read-write` entitlement.

Using App Sandbox is required if you plan to distribute your application in the
App Store.

**Important**: `com.apple.security.network.server`, which allows incoming
network connections, is enabled by default only for Debug and Profile
(to enable the Dart observatory). If you need to allow incoming network
requests in your application, you must add it to `Runner-Release.entitlements`
as well, otherwise your app will work correctly in Debug testing, but fail
with Release builds.

## Hardened Runtime

If you choose to distribute your application outside the App Store, you will
need to
[notarize](https://developer.apple.com/documentation/security/notarizing_your_app_before_distribution)
your application for compatibility with macOS 10.15+. This requires enabling
the [Hardened
Runtime](https://developer.apple.com/documentation/security/hardened_runtime_entitlements)
option. It is not on by default in the example project because enabling it
requires adding a valid signing certificate in order to build.

By default, the entitlements file in the example will allow JIT for Debug
builds, but as with App Sandbox you may need to manage [other
entitlements](https://developer.apple.com/documentation/security/hardened_runtime_entitlements#3111190).
If you have both App Sandbox and Hardened Runtime enabled, you may need to
add multiple entitlements for the same resource. For instance, microphone access
would require *both* `com.apple.security.device.audio-input` (for Hardened
Runtime) and `com.apple.security.device.microphone` (for App Sandbox).

## Feedback

Please file issues or [email the mailing
list](https://groups.google.com/forum/#!forum/flutter-desktop-embedding-dev)
if you have feedback about the process of using App Sandbox and/or Hardened
Runtime, as we would like to understand as much as possible about issues or
pain points in using them with Flutter applications.

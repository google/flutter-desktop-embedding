# Quick Start

A common question for people discovering this project is: How do I easily add
desktop support to my existing Flutter application?

The answer is that at this point, you don't. The project is still in early
stages, and a lot of things are still in flux; if you don't already have
experience doing desktop development on the platform(s) you want to add,
this project is probably not ready for you to use it yet. The focus is currently
on improving core functionality, not on ease of use. Neither the API surface nor
the project structure are stable, and no attempt will be made to provide
supported migration paths as things change.

However, if you want to try out an existing Flutter application running on the
desktop even with those caveats, and don't have experience with desktop
development, here are two approaches that might work for you.

With either approach, be sure to follow the [main README](README.md) and
[library README](library/README.md) instructions on setting up prerequisites
and adjusting your Flutter application.

## Replace the 'example' Flutter Code

Since `example/` is already configured to run on all the platforms this project
supports, you can swap in your project's Dart code, `pubspec.yaml`, resources,
etc., then follow the [normal directions](example/README.md) for building the
example application on your platform.

This will be the easiest approach to keep working as the project changes, but
requires that you essentially wrap your whole application in a
flutter-desktop-embedding checkout.

## Copy the '\*\_fde' Directories

Starting from the example projects means you don't have to create projects from
scratch, and since they are self-contained they can be added to an existing
project without needing to move it. However, because the projects build
the flutter-desktop-embedding libraries from source, they contain relative paths
to the flutter-desktop-embedding projects and tools they depend on. You will
need to update those paths in order for the projects to work. On Linux, the
variables you will need to change are documented in the Makefile. On macOS and
Windows, you will need some familiarity with Xcode and Visual Studio
respectively to make the changes.

With this approach, you should expect breakage when you update the
flutter-desktop-embedding reposity; when that happens you will need to look at
what has changed in the example projects and update your copies accordingly, or
start over with fresh copies and adjust the paths again.

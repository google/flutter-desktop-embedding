# This file contains variables that applications are likely to need to
# change, to isolate them from the main Makefile where the build rules are still
# in flux. This should simplify re-creating the runner while preserving local
# changes.

# Executable name.
BINARY_NAME=flutter_desktop_example
# Any extra source files to build.
EXTRA_SOURCES=
# Paths of any additional libraries to be bundled in the output directory.
EXTRA_BUNDLED_LIBRARIES=
# Extra flags (e.g., for library dependencies).
SYSTEM_LIBRARIES=
EXTRA_CXXFLAGS=
EXTRA_CPPFLAGS=
EXTRA_LDFLAGS=
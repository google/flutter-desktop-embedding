# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Example-specific variables.
# To modify this Makefile for a different application, these are the values
# that are mostly likely to need to be changed.

# Executable name.
BINARY_NAME=flutter_desktop_example
# The location of the flutter-desktop-embedding repository.
FDE_ROOT=$(CURDIR)/../..
# The C++ code for the embedder application.
SOURCES=flutter_embedder_example.cc


# Default build type. For a release build, set BUILD=release.
# Currently this only sets NDEBUG, which is used to control the flags passed
# to the Flutter engine in the example shell, and not the complation settings
# (e.g., optimization level) of the C++ code.
BUILD:=debug

# Dependency locations
FLUTTER_APP_DIR=$(CURDIR)/..
FLUTTER_APP_BUILD_DIR=$(FLUTTER_APP_DIR)/build
FLUTTER_EMBEDDER_LIB_DIR=$(FDE_ROOT)/library/linux
TOOLS_DIR=$(FDE_ROOT)/tools
FLUTTER_DIR=$(shell $(TOOLS_DIR)/flutter_location)

OUT_DIR=$(FLUTTER_APP_BUILD_DIR)/linux
CACHE_DIR=$(OUT_DIR)/cache
FLUTTER_LIBRARY_DIR=$(CACHE_DIR)/flutter_library

FLUTTER_LIB_NAME=flutter_linux
FLUTTER_LIB=$(FLUTTER_LIBRARY_DIR)/lib$(FLUTTER_LIB_NAME).so

# Tools
BUILD_ASSETS_BIN=$(TOOLS_DIR)/build_flutter_assets
SYNC_FLUTTER_LIBRARY_BIN=$(TOOLS_DIR)/sync_flutter_library
FLUTTER_BIN=$(FLUTTER_DIR)/bin/flutter

# Resources
ICU_DATA_NAME=icudtl.dat
ICU_DATA_SOURCE=$(FLUTTER_DIR)/bin/cache/artifacts/engine/linux-x64/$(ICU_DATA_NAME)
FLUTTER_ASSETS_NAME=flutter_assets
FLUTTER_ASSETS_SOURCE=$(FLUTTER_APP_BUILD_DIR)/$(FLUTTER_ASSETS_NAME)

# Bundle structure
BUNDLE_OUT_DIR=$(OUT_DIR)/$(BUILD)
BUNDLE_DATA_DIR=$(BUNDLE_OUT_DIR)/data
BUNDLE_LIB_DIR=$(BUNDLE_OUT_DIR)/lib

BIN_OUT=$(BUNDLE_OUT_DIR)/$(BINARY_NAME)
ICU_DATA_OUT=$(BUNDLE_DATA_DIR)/$(ICU_DATA_NAME)
FLUTTER_LIB_OUT=$(BUNDLE_LIB_DIR)/$(notdir $(FLUTTER_LIB))

# Add relevant code from the wrapper library, which is intended to be statically
# built into the client.
WRAPPER_ROOT=$(FLUTTER_LIBRARY_DIR)/cpp_client_wrapper
WRAPPER_SOURCES= \
	$(WRAPPER_ROOT)/flutter_window_controller.cc \
	$(WRAPPER_ROOT)/plugin_registrar.cc \
	$(WRAPPER_ROOT)/engine_method_result.cc
SOURCES+=$(WRAPPER_SOURCES)

# Headers
WRAPPER_INCLUDE_DIR=$(WRAPPER_ROOT)/include
INCLUDE_DIRS=$(FLUTTER_LIBRARY_DIR) $(WRAPPER_INCLUDE_DIR)

# The stamp file created by sync_flutter_library.
FLUTTER_LIBRARY_STAMP_FILE=$(FLUTTER_LIBRARY_DIR)/.last_flutter_version

# Build settings
CXX=g++ -std=c++14
CXXFLAGS.release=-DNDEBUG
CXXFLAGS=-Wall -Werror $(CXXFLAGS.$(BUILD))
CPPFLAGS=$(patsubst %,-I%,$(INCLUDE_DIRS))
LDFLAGS=-L$(BUNDLE_LIB_DIR) \
	-l$(FLUTTER_LIB_NAME) \
	-Wl,-rpath=\$$ORIGIN/lib

# Targets

.PHONY: all
all: $(BIN_OUT) bundle

.PHONY: bundle
bundle: $(ICU_DATA_OUT) $(FLUTTER_LIB_OUT) bundleflutterassets

$(BIN_OUT): $(SOURCES) $(FLUTTER_LIB_OUT)
	mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(SOURCES) $(LDFLAGS) -o $@

$(WRAPPER_SOURCES) $(FLUTTER_LIB): $(FLUTTER_LIBRARY_STAMP_FILE)

# Use an order-only dependency to avoid unnecessary relinking when
# sync_flutter_library is a no-op.
$(FLUTTER_LIBRARY_STAMP_FILE): | sync_flutter_library

# This is phony since it should always run; otherwise local engine build changes
# won't be picked up. For the normal case, the script knows how to avoid doing
# unnecessary work, so running it is fast.
.PHONY: sync_flutter_library
sync_flutter_library:
	$(TOOLS_DIR)/sync_flutter_library $(FLUTTER_LIBRARY_DIR)

$(FLUTTER_LIB_OUT): $(FLUTTER_LIB)
	mkdir -p $(BUNDLE_LIB_DIR)
	cp $(FLUTTER_LIB) $(BUNDLE_LIB_DIR)

$(ICU_DATA_OUT): $(ICU_DATA_SOURCE)
	mkdir -p $(dir $(ICU_DATA_OUT))
	cp $(ICU_DATA_SOURCE) $(ICU_DATA_OUT)

# Fully re-copy the assets directory on each build to avoid having to keep a
# comprehensive list of all asset files here, which would be fragile to changes
# in the Flutter example (e.g., adding a new font to pubspec.yaml would require
# changes here).
.PHONY: bundleflutterassets
bundleflutterassets: $(FLUTTER_ASSETS_SOURCE)
	mkdir -p $(BUNDLE_DATA_DIR)
	rsync -rpu --delete $(FLUTTER_ASSETS_SOURCE) $(BUNDLE_DATA_DIR)

# PHONY since the Makefile doesn't have all the dependency information necessary
# to know if 'build bundle' needs to be re-run.
.PHONY: $(FLUTTER_ASSETS_SOURCE)
$(FLUTTER_ASSETS_SOURCE):
	$(BUILD_ASSETS_BIN) $(FLUTTER_APP_DIR)

.PHONY: clean
clean:
	rm -rf $(OUT_DIR); \
	cd $(FLUTTER_APP_DIR); \
	$(FLUTTER_BIN) clean

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
BINARY_NAME=testbed
# The location of the flutter-desktop-embedding repository.
FDE_ROOT=$(CURDIR)/../..
# The C++ code for the embedder application.
SOURCES=testbed.cc
# Plugins to include (from the flutter-desktop-embedding plugins/ directory).
PLUGIN_NAMES=color_panel file_chooser menubar window_size


# Default build type. For a release build, set BUILD=release.
# Currently this only sets NDEBUG, which is used to control the flags passed
# to the Flutter engine in the example shell, and not the complation settings
# (e.g., optimization level) of the C++ code.
BUILD=debug

# Configuration provided via flutter tool.
include flutter/generated_config

# Dependency locations
FLUTTER_APP_CACHE_DIR=flutter/
FLUTTER_APP_DIR=$(CURDIR)/..
FLUTTER_APP_BUILD_DIR=$(FLUTTER_APP_DIR)/build
PLUGINS_DIR=$(FDE_ROOT)/plugins
GN_OUT_DIR=$(FDE_ROOT)/out

OUT_DIR=$(FLUTTER_APP_BUILD_DIR)/linux

# Libraries
FLUTTER_LIB_NAME=flutter_linux
FLUTTER_LIB=$(FLUTTER_APP_CACHE_DIR)/lib$(FLUTTER_LIB_NAME).so

PLUGIN_LIB_NAME_PREFIX=flutter_embedder_
PLUGIN_LIBS=$(foreach plugin,$(PLUGIN_NAMES)\
	,$(GN_OUT_DIR)/lib$(PLUGIN_LIB_NAME_PREFIX)$(plugin).so)

ALL_LIBS=$(FLUTTER_LIB) $(PLUGIN_LIBS)

# Tools
FLUTTER_BIN=$(FLUTTER_ROOT)/bin/flutter
GN_WRAPPER=$(FDE_ROOT)/tools/gn_dart
NINJA_BIN=ninja

# Resources
ICU_DATA_NAME=icudtl.dat
ICU_DATA_SOURCE=$(FLUTTER_APP_CACHE_DIR)/$(ICU_DATA_NAME)
FLUTTER_ASSETS_NAME=flutter_assets
FLUTTER_ASSETS_SOURCE=$(FLUTTER_APP_BUILD_DIR)/$(FLUTTER_ASSETS_NAME)

# Bundle structure
BUNDLE_OUT_DIR=$(OUT_DIR)/$(BUILD)
BUNDLE_DATA_DIR=$(BUNDLE_OUT_DIR)/data
BUNDLE_LIB_DIR=$(BUNDLE_OUT_DIR)/lib

BIN_OUT=$(BUNDLE_OUT_DIR)/$(BINARY_NAME)
ICU_DATA_OUT=$(BUNDLE_DATA_DIR)/$(ICU_DATA_NAME)
ALL_LIBS_OUT=$(foreach lib,$(ALL_LIBS),$(BUNDLE_LIB_DIR)/$(notdir $(lib)))

# Add relevant code from the wrapper library, which is intended to be statically
# built into the client.
WRAPPER_ROOT=$(FLUTTER_APP_CACHE_DIR)/cpp_client_wrapper
WRAPPER_SOURCES= \
	$(WRAPPER_ROOT)/flutter_window_controller.cc \
	$(WRAPPER_ROOT)/plugin_registrar.cc \
	$(WRAPPER_ROOT)/engine_method_result.cc
SOURCES+=$(WRAPPER_SOURCES)

# Headers
WRAPPER_INCLUDE_DIR=$(WRAPPER_ROOT)/include
# The GN build places all published headers in a top-level include/.
PLUGIN_INCLUDE_DIRS+=$(GN_OUT_DIR)/include
INCLUDE_DIRS=$(FLUTTER_APP_CACHE_DIR) $(PLUGIN_INCLUDE_DIRS) \
	$(WRAPPER_INCLUDE_DIR)

# Build settings
CXX=g++ -std=c++14
CXXFLAGS.release=-DNDEBUG
CXXFLAGS=-Wall -Werror $(CXXFLAGS.$(BUILD))
CPPFLAGS=$(patsubst %,-I%,$(INCLUDE_DIRS))
LDFLAGS=-L$(BUNDLE_LIB_DIR) \
	-l$(FLUTTER_LIB_NAME) \
	$(patsubst %,-l$(PLUGIN_LIB_NAME_PREFIX)%,$(PLUGIN_NAMES)) \
	-Wl,-rpath=\$$ORIGIN/lib

# Targets

.PHONY: all
all: $(BIN_OUT) bundle

# This is a phony target because the flutter tool cannot describe
# its inputs and outputs yet.
.PHONY: sync
sync: flutter/generated_config
	$(FLUTTER_ROOT)/packages/flutter_tools/bin/tool_backend.sh linux-x64 $(BUILD)

.PHONY: bundle
bundle: $(ICU_DATA_OUT) $(ALL_LIBS_OUT) bundleflutterassets

$(BIN_OUT): $(SOURCES) $(ALL_LIBS_OUT)
	mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(SOURCES) $(LDFLAGS) -o $@

$(WRAPPER_SOURCES) $(FLUTTER_LIB) $(ICU_DATA_SOURCE) $(FLUTTER_ASSETS_SOURCE): \
	| sync

# Run the GN build for anything depending on the plugins, but use order-only
# so that it doesn't trigger rebuilds of all dependencies every time.
$(PLUGIN_LIBS): | gnbuild

.PHONY: gnbuild
gnbuild $(WRAPPER_SOURCES): $(GN_OUT_DIR)
	$(NINJA_BIN) -C $(GN_OUT_DIR) $(PLUGIN_NAMES)

$(GN_OUT_DIR):
	$(GN_WRAPPER) gen $(GN_OUT_DIR)

# This is slightly inefficient in that it copies all libraries if any of them
# changes, but is far simpler than setting up individual rules for each library.
$(ALL_LIBS_OUT): $(ALL_LIBS)
	mkdir -p $(BUNDLE_LIB_DIR)
	cp $(ALL_LIBS) $(BUNDLE_LIB_DIR)

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

.PHONY: clean
clean:
	rm -rf $(OUT_DIR); \
	cd $(FLUTTER_APP_DIR); \
	$(FLUTTER_BIN) clean

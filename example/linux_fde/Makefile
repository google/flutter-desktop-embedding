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

# The location of the flutter-desktop-embedding repository.
FDE_ROOT=$(CURDIR)/../..
# The C++ code for the embedder application.
SOURCES=flutter_embedder_example.cc
# Plugins to include (from the flutter-desktop-embedding plugins/ directory).
PLUGIN_NAMES=color_panel file_chooser menubar


# Default build type. For a release build, set BUILD=release.
# Currently this only sets NDEBUG, which is used to control the flags passed
# to the Flutter engine in the example shell, and not the complation settings
# (e.g., optimization level) of the C++ code.
BUILD:=debug

# Dependency locations
FLUTTER_APP_DIR=$(CURDIR)/..
FLUTTER_APP_BUILD_DIR=$(FLUTTER_APP_DIR)/build
FLUTTER_EMBEDDER_LIB_DIR=$(FDE_ROOT)/library/linux
PLUGINS_DIR=$(FDE_ROOT)/plugins
TOOLS_DIR=$(FDE_ROOT)/tools
FLUTTER_DIR=$(shell $(TOOLS_DIR)/flutter_location)

# Libraries
FLUTTER_EMBEDDER_LIB_NAME=flutter_embedder
FLUTTER_EMBEDDER_LIB=$(FLUTTER_EMBEDDER_LIB_DIR)/lib$(FLUTTER_EMBEDDER_LIB_NAME).so

FLUTTER_ENGINE_LIB_NAME=flutter_engine
FLUTTER_ENGINE_LIB=$(FLUTTER_EMBEDDER_LIB_DIR)/lib$(FLUTTER_ENGINE_LIB_NAME).so

PLUGIN_LIB_NAME_PREFIX=flutter_embedder_
PLUGIN_LIBS=$(foreach plugin,$(PLUGIN_NAMES)\
	,$(PLUGINS_DIR)/$(plugin)/linux/lib$(PLUGIN_LIB_NAME_PREFIX)$(plugin).so)

ALL_LIBS=$(FLUTTER_EMBEDDER_LIB) $(FLUTTER_ENGINE_LIB) $(PLUGIN_LIBS)

# Headers
PLUGIN_DIRS=$(patsubst %,$(PLUGINS_DIR)/%/linux,$(PLUGIN_NAMES))
LIBRARY_DIRS=$(FLUTTER_EMBEDDER_LIB_DIR) $(PLUGIN_DIRS)
INCLUDE_DIRS=$(patsubst %,%/include,$(LIBRARY_DIRS)) $(FDE_ROOT)/library/include

# Tools
BUILD_ASSETS_BIN=$(TOOLS_DIR)/build_flutter_assets
FLUTTER_BIN=$(FLUTTER_DIR)/bin/flutter

# Resources
ICU_DATA_NAME=icudtl.dat
ICU_DATA_SOURCE=$(FLUTTER_DIR)/bin/cache/artifacts/engine/linux-x64/$(ICU_DATA_NAME)
FLUTTER_ASSETS_NAME=flutter_assets
FLUTTER_ASSETS_SOURCE=$(FLUTTER_APP_BUILD_DIR)/$(FLUTTER_ASSETS_NAME)

# Output bundle structure and targets
OUT_DIR=$(FLUTTER_APP_BUILD_DIR)/linux_fde/$(BUILD)
OUT_DATA_DIR=$(OUT_DIR)/data
OUT_LIB_DIR=$(OUT_DIR)/lib

BIN_OUT=$(OUT_DIR)/flutter_embedder_example
ICU_DATA_OUT=$(OUT_DATA_DIR)/$(ICU_DATA_NAME)
ALL_LIBS_OUT=$(foreach lib,$(ALL_LIBS),$(OUT_LIB_DIR)/$(notdir $(lib)))

# Overrides for the optional GN build.
ifdef USE_GN
GN_OUT_DIR=$(FDE_ROOT)/out

# The GN build places all libraries at the top level of the output directory.
FLUTTER_EMBEDDER_LIB=$(GN_OUT_DIR)/lib$(FLUTTER_EMBEDDER_LIB_NAME).so
FLUTTER_ENGINE_LIB=$(GN_OUT_DIR)/lib$(FLUTTER_ENGINE_LIB_NAME).so
PLUGIN_LIBS=$(foreach plugin,$(PLUGIN_NAMES)\
	,$(GN_OUT_DIR)/lib$(PLUGIN_LIB_NAME_PREFIX)$(plugin).so)

# The GN build places all published headers in a top-level include/.
INCLUDE_DIRS=$(GN_OUT_DIR)/include

# Override LIBRARY_DIRS since it's used for controlling the external build.
LIBRARY_DIRS=$(GN_OUT_DIR)

# Additional tools
GN_WRAPPER=$(TOOLS_DIR)/gn_dart
NINJA_BIN=ninja
endif

# Build settings
CXX=g++ -std=c++14
CXXFLAGS.release=-DNDEBUG
CXXFLAGS=-Wall -Werror $(shell pkg-config --cflags jsoncpp glfw3) \
				 $(CXXFLAGS.$(BUILD))
CPPFLAGS=$(patsubst %,-I%,$(INCLUDE_DIRS))
ifdef USE_GN
CPPFLAGS+=-DUSE_FLATTENED_INCLUDES
endif
LDFLAGS=-L$(OUT_LIB_DIR) \
	$(shell pkg-config --libs jsoncpp glfw3) \
	-l$(FLUTTER_EMBEDDER_LIB_NAME) \
	-l$(FLUTTER_ENGINE_LIB_NAME) \
	$(patsubst %,-l$(PLUGIN_LIB_NAME_PREFIX)%,$(PLUGIN_NAMES)) \
	-Wl,-rpath=\$$ORIGIN/lib

# Targets

.PHONY: all
all: $(BIN_OUT) bundle

.PHONY: bundle
bundle: $(ICU_DATA_OUT) $(ALL_LIBS_OUT) bundleflutterassets

$(BIN_OUT): $(SOURCES) $(ALL_LIBS_OUT)
	mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(SOURCES) $(LDFLAGS) -o $@

# Depedency directories are used as phony targets to invoke their builds.
ifdef USE_GN
.PHONY: $(LIBRARY_DIRS)
$(LIBRARY_DIRS):
	$(GN_WRAPPER) gen $(GN_OUT_DIR)
	$(NINJA_BIN) -C $(GN_OUT_DIR) $(FLUTTER_EMBEDDER_LIB_NAME) $(PLUGIN_NAMES)
else
.PHONY: $(LIBRARY_DIRS)
$(LIBRARY_DIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

# Enforce relative ordering. This prevents accidentally building the targets
# in parallel in the event that someone supplies the -j flag to `make`.
# TODO: Fix this in the plugin builds so that it's not necessary at this layer.
$(PLUGIN_DIRS): $(FLUTTER_EMBEDDER_LIB_DIR)
endif

# Require that all the library builds run for anything depending on the
# libraries, but use order-only so that the phony build targets don't trigger
# rebuilds of all dependencies every time.
$(ALL_LIBS): | $(LIBRARY_DIRS)

# This is slightly inefficient in that it copies all libraries if any of them
# changes, but is far simpler than setting up individual rules for each library.
$(ALL_LIBS_OUT): $(ALL_LIBS)
	mkdir -p $(OUT_LIB_DIR)
	cp $(ALL_LIBS) $(OUT_LIB_DIR)

$(ICU_DATA_OUT): $(ICU_DATA_SOURCE)
	mkdir -p $(dir $(ICU_DATA_OUT))
	cp $(ICU_DATA_SOURCE) $(ICU_DATA_OUT)

# Fully re-copy the assets directory on each build to avoid having to keep a
# comprehensive list of all asset files here, which would be fragile to changes
# in the Flutter example (e.g., adding a new font to pubspec.yaml would require
# changes here).
.PHONY: bundleflutterassets
bundleflutterassets: $(FLUTTER_ASSETS_SOURCE)
	mkdir -p $(OUT_DATA_DIR)
	rsync -rpu --delete $(FLUTTER_ASSETS_SOURCE) $(OUT_DATA_DIR)

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

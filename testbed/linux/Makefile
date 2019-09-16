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

# Executable name.
BINARY_NAME=testbed
# Any extra source files to build.
EXTRA_SOURCES=
# Paths of any additional libraries to be bundled in the output directory.
EXTRA_BUNDLED_LIBRARIES=
# Extra flags (e.g., for library dependencies).
SYSTEM_LIBRARIES=gtk+-3.0 x11
EXTRA_CXXFLAGS=
EXTRA_CPPFLAGS=
EXTRA_LDFLAGS=

# The location of the flutter-desktop-embedding repository.
FDE_ROOT=$(CURDIR)/../..
# Plugins to include from the flutter-desktop-embedding plugins/ directory.
PLUGIN_NAMES=color_panel file_chooser menubar window_size
# Additional plugins to include from the plugins/flutter_plugins subdirectory.
FLUTTER_PLUGIN_NAMES=url_launcher_fde


# Default build type. For a release build, set BUILD=release.
# Currently this only sets NDEBUG, which is used to control the flags passed
# to the Flutter engine in the example shell, and not the complation settings
# (e.g., optimization level) of the C++ code.
BUILD=debug

FLUTTER_EPHEMERAL_DIR=flutter/ephemeral

# Configuration provided via flutter tool.
FLUTTER_CONFIG_FILE=$(FLUTTER_EPHEMERAL_DIR)/generated_config.mk
include $(FLUTTER_CONFIG_FILE)

# Dependency locations
FLUTTER_APP_DIR=$(CURDIR)/..
FLUTTER_APP_BUILD_DIR=$(FLUTTER_APP_DIR)/build

OUT_DIR=$(FLUTTER_APP_BUILD_DIR)/linux
OBJ_DIR=$(OUT_DIR)/obj

# Libraries
FLUTTER_LIB_NAME=flutter_linux_glfw
FLUTTER_LIB=$(FLUTTER_EPHEMERAL_DIR)/lib$(FLUTTER_LIB_NAME).so

# Tools
FLUTTER_BIN=$(FLUTTER_ROOT)/bin/flutter
LINUX_BUILD=$(FLUTTER_ROOT)/packages/flutter_tools/bin/tool_backend.sh

# Resources
ICU_DATA_NAME=icudtl.dat
ICU_DATA_SOURCE=$(FLUTTER_EPHEMERAL_DIR)/$(ICU_DATA_NAME)
FLUTTER_ASSETS_NAME=flutter_assets
FLUTTER_ASSETS_SOURCE=$(FLUTTER_APP_BUILD_DIR)/$(FLUTTER_ASSETS_NAME)

# Plugin-related additions
# Currently plugins are refenced by direct source path. Eventually this should
# be pub-based instead as on other platforms.
PLUGINS_DIR=$(FDE_ROOT)/plugins
FLUTTER_PLUGINS_DIR=$(PLUGINS_DIR)/flutter_plugins
# The name of each plugin library is the name of its directory with _plugin
# appended. The exception is example_plugin (to avoid confusion with the
# top-level example/ directory), so it's added here separately.
PLUGIN_LIB_NAMES=$(foreach plugin,$(PLUGIN_NAMES) $(FLUTTER_PLUGIN_NAMES),$(plugin)_plugin) example_plugin
PLUGIN_LIBS=$(foreach plugin,$(PLUGIN_LIB_NAMES),$(OUT_DIR)/lib$(plugin).so)
EXTRA_BUNDLED_LIBRARIES+=$(PLUGIN_LIBS)
EXTRA_LDFLAGS+=$(patsubst %,-l%,$(PLUGIN_LIB_NAMES))
# The plugin builds place all published headers in a top-level include/.
EXTRA_CPPFLAGS+=-I$(OUT_DIR)/include

# Bundle structure
BUNDLE_OUT_DIR=$(OUT_DIR)/$(BUILD)
BUNDLE_DATA_DIR=$(BUNDLE_OUT_DIR)/data
BUNDLE_LIB_DIR=$(BUNDLE_OUT_DIR)/lib

BIN_OUT=$(BUNDLE_OUT_DIR)/$(BINARY_NAME)
ICU_DATA_OUT=$(BUNDLE_DATA_DIR)/$(ICU_DATA_NAME)
FLUTTER_LIB_OUT=$(BUNDLE_LIB_DIR)/$(notdir $(FLUTTER_LIB))
ALL_LIBS_OUT=$(FLUTTER_LIB_OUT) \
	$(foreach lib,$(EXTRA_BUNDLED_LIBRARIES),$(BUNDLE_LIB_DIR)/$(notdir $(lib)))

# Add relevant code from the wrapper library, which is intended to be statically
# built into the client.
# Use abspath for the wrapper root, which can contain relative paths; the
# intermediate build files will be based on the source path, which will cause
# issues if they start with one or more '../'s.
WRAPPER_ROOT=$(abspath $(FLUTTER_EPHEMERAL_DIR)/cpp_client_wrapper_glfw)
WRAPPER_SOURCES= \
	$(WRAPPER_ROOT)/flutter_window_controller.cc \
	$(WRAPPER_ROOT)/plugin_registrar.cc \
	$(WRAPPER_ROOT)/engine_method_result.cc

# Use abspath for extra sources, which may also contain relative paths (see
# note above about WRAPPER_ROOT).
SOURCES=main.cc $(WRAPPER_SOURCES) $(abspath $(EXTRA_SOURCES))

# Headers
WRAPPER_INCLUDE_DIR=$(WRAPPER_ROOT)/include
INCLUDE_DIRS=$(FLUTTER_EPHEMERAL_DIR) $(WRAPPER_INCLUDE_DIR)

# Build settings
ifneq ($(strip $(SYSTEM_LIBRARIES)),)
EXTRA_CPPFLAGS+=$(patsubst -I%,-isystem%,$(shell pkg-config --cflags $(SYSTEM_LIBRARIES)))
EXTRA_LDFLAGS+=$(shell pkg-config --libs $(SYSTEM_LIBRARIES))
endif
CXX=clang++ $(EXTRA_CXXFLAGS)
CXXFLAGS.release=-DNDEBUG
CXXFLAGS=-std=c++14 -Wall -Werror $(CXXFLAGS.$(BUILD))
CPPFLAGS=$(patsubst %,-I%,$(INCLUDE_DIRS)) $(EXTRA_CPPFLAGS)
LDFLAGS=-L$(BUNDLE_LIB_DIR) \
	-l$(FLUTTER_LIB_NAME) \
	$(EXTRA_LDFLAGS) \
	-Wl,-rpath=\$$ORIGIN/lib

# Intermediate files.
OBJ_FILES=$(SOURCES:%.cc=$(OBJ_DIR)/%.o)
DEPENDENCY_FILES=$(OBJ_FILES:%.o=%.d)

# Targets

.PHONY: all
all: $(BIN_OUT) bundle

# This is a phony target because the flutter tool cannot describe
# its inputs and outputs yet.
.PHONY: sync
sync: $(FLUTTER_CONFIG_FILE)
	$(LINUX_BUILD) linux-x64 $(BUILD)

.PHONY: bundle
bundle: $(ICU_DATA_OUT) $(ALL_LIBS_OUT) bundleflutterassets

$(BIN_OUT): $(OBJ_FILES) $(ALL_LIBS_OUT)
	mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OBJ_FILES) $(LDFLAGS) -o $@

$(WRAPPER_SOURCES) $(FLUTTER_LIB) $(ICU_DATA_SOURCE) $(FLUTTER_ASSETS_SOURCE): \
	| sync

# Implicit rules won't match phony targets, so list plugin builds explicitly.
$(OUT_DIR)/libexample_plugin.so: | example_plugin
$(OUT_DIR)/libcolor_panel_plugin.so: | color_panel
$(OUT_DIR)/libfile_chooser_plugin.so: | file_chooser
$(OUT_DIR)/libmenubar_plugin.so: | menubar
$(OUT_DIR)/libwindow_size_plugin.so: | window_size
$(OUT_DIR)/liburl_launcher_fde_plugin.so: | url_launcher_fde

# Compilation depends on plugin headers that are copied as part of the
# plugin builds, so ensure those happen first.
# TODO: Restructure to avoid the need for this.
$(OBJ_FILES) : | $(EXTRA_BUNDLED_LIBRARIES)

.PHONY: $(PLUGIN_NAMES) example_plugin
$(PLUGIN_NAMES) example_plugin:
	make -C $(PLUGINS_DIR)/$@/linux \
		OUT_DIR=$(OUT_DIR) FLUTTER_ROOT=$(FLUTTER_ROOT)

.PHONY: $(FLUTTER_PLUGIN_NAMES)
$(FLUTTER_PLUGIN_NAMES):
	make -C $(FLUTTER_PLUGINS_DIR)/$@/linux \
		OUT_DIR=$(OUT_DIR) FLUTTER_ROOT=$(FLUTTER_ROOT)

# Plugin library bundling pattern.
$(BUNDLE_LIB_DIR)/%: $(OUT_DIR)/%
	mkdir -p $(BUNDLE_LIB_DIR)
	cp $< $@

$(FLUTTER_LIB_OUT): $(FLUTTER_LIB)
	mkdir -p $(@D)
	cp $< $@

$(ICU_DATA_OUT): $(ICU_DATA_SOURCE)
	mkdir -p $(@D)
	cp $< $@

-include $(DEPENDENCY_FILES)

$(OBJ_DIR)/%.o : %.cc | sync
	mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -MMD -c $< -o $@

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

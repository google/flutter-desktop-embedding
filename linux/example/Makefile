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

# Dependency locations
FLUTTER_EMBEDDER_LIB_DIR=$(CURDIR)/../library
FLUTTER_APP_DIR=$(CURDIR)/../../example_flutter
PLUGINS_DIR=$(CURDIR)/../../plugins
TOOLS_DIR=../../tools
FLUTTER_DIR=$(shell $(TOOLS_DIR)/flutter_location)

# Libraries
FLUTTER_EMBEDDER_LIB_NAME=flutter_embedder
FLUTTER_EMBEDDER_LIB=$(FLUTTER_EMBEDDER_LIB_DIR)/lib$(FLUTTER_EMBEDDER_LIB_NAME).so

FLUTTER_ENGINE_LIB_NAME=flutter_engine
FLUTTER_ENGINE_LIB=$(FLUTTER_EMBEDDER_LIB_DIR)/lib$(FLUTTER_ENGINE_LIB_NAME).so

PLUGIN_NAMES=color_panel file_chooser
PLUGIN_LIB_NAME_PREFIX=flutter_embedder_
PLUGIN_LIBS=$(foreach plugin,$(PLUGIN_NAMES)\
	,$(PLUGINS_DIR)/$(plugin)/linux/lib$(PLUGIN_LIB_NAME_PREFIX)$(plugin).so)

ALL_LIBS=$(FLUTTER_EMBEDDER_LIB) $(FLUTTER_ENGINE_LIB) $(PLUGIN_LIBS)

# Headers
PLUGIN_DIRS=$(patsubst %,$(PLUGINS_DIR)/%/linux,$(PLUGIN_NAMES))
LIBRARY_DIRS=$(FLUTTER_EMBEDDER_LIB_DIR) $(PLUGIN_DIRS)
INCLUDE_DIRS=$(patsubst %,%/include,$(LIBRARY_DIRS))

# Tools
BUILD_ASSETS_BIN=$(TOOLS_DIR)/build_flutter_assets
FLUTTER_BIN=$(FLUTTER_DIR)/bin/flutter

# Resources
ICU_DATA_NAME=icudtl.dat
ICU_DATA_SOURCE=$(FLUTTER_DIR)/bin/cache/artifacts/engine/linux-x64/$(ICU_DATA_NAME)
FLUTTER_ASSETS_NAME=flutter_assets
FLUTTER_ASSETS_SOURCE=$(FLUTTER_APP_DIR)/build/$(FLUTTER_ASSETS_NAME)

# Output bundle structure and targets
OUT_DIR=$(CURDIR)/out
OUT_DATA_DIR=$(OUT_DIR)/data
OUT_LIB_DIR=$(OUT_DIR)/lib

BIN_OUT=$(OUT_DIR)/flutter_embedder_example
ICU_DATA_OUT=$(OUT_DATA_DIR)/$(ICU_DATA_NAME)
ALL_LIBS_OUT=$(foreach lib,$(ALL_LIBS),$(OUT_LIB_DIR)/$(notdir $(lib)))

# Build settings
CXX=g++ -std=c++14
CXXFLAGS=-Wall -Werror $(shell pkg-config --cflags jsoncpp)
CPPFLAGS=$(patsubst %,-I%,$(INCLUDE_DIRS))
LDFLAGS=-L$(OUT_LIB_DIR) \
	-lglfw \
	$(shell pkg-config --libs jsoncpp) \
	-l$(FLUTTER_EMBEDDER_LIB_NAME) \
	-l$(FLUTTER_ENGINE_LIB_NAME) \
	$(patsubst %,-l$(PLUGIN_LIB_NAME_PREFIX)%,$(PLUGIN_NAMES)) \
	-Wl,-rpath=\$$ORIGIN/lib

SOURCES=flutter_embedder_example.cc

# Targets

.PHONY: all
all: $(BIN_OUT) bundle

.PHONY: bundle
bundle: $(ICU_DATA_OUT) $(ALL_LIBS_OUT) bundleflutterassets

$(BIN_OUT): $(SOURCES) $(ALL_LIBS_OUT)
	mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(SOURCES) $(LDFLAGS) -o $@

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

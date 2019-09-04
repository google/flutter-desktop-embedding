# Copyright 2019 Google LLC
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

# The name of the plugin.
# The primary source file is assumed to be $(PLUGIN_NAME).cc, with
# $(PLUGIN_NAME).h as the public header meant for inclusion by the application.
PLUGIN_NAME=file_chooser_plugin
# Any files other than the plugin class files that need to be compiled.
EXTRA_SOURCES=
# Extra flags (e.g., for library dependencies).
SYSTEM_LIBRARIES=gtk+-3.0
EXTRA_CXXFLAGS=
EXTRA_CPPFLAGS=-I../../.. \
	$(patsubst -I%,-isystem%,$(shell pkg-config --cflags $(SYSTEM_LIBRARIES)))
EXTRA_LDFLAGS=$(shell pkg-config --libs $(SYSTEM_LIBRARIES))

# Default build type. For a release build, set BUILD=release.
# Currently this only sets NDEBUG, which is used to control the flags passed
# to the Flutter engine in the example shell, and not the complation settings
# (e.g., optimization level) of the C++ code.
BUILD=debug

# Dependency locations
# Default to building in the plugin directory.
OUT_DIR=$(CURDIR)/../build/linux
# Sharing an OUT_DIR will be common, so use a subdirectory for intermediates.
PLUGIN_OUT_DIR=$(OUT_DIR)/$(PLUGIN_NAME)
OBJ_DIR=$(PLUGIN_OUT_DIR)/obj
FLUTTER_CACHE_DIR=$(PLUGIN_OUT_DIR)/flutter

# Flutter library
FLUTTER_LIB_NAME=flutter_linux_glfw
FLUTTER_LIB=$(FLUTTER_CACHE_DIR)/lib$(FLUTTER_LIB_NAME).so

# If FLUTTER_ROOT is set, use that version of Flutter. Otherwise, assume that
# the flutter tool is in the path.
ifeq ($(strip $(FLUTTER_ROOT)),)
FLUTTER_BIN=flutter
else
FLUTTER_BIN=$(FLUTTER_ROOT)/bin/flutter
endif

# Unpack configuration.
# TODO: Revisit how this is managed, either by having plugins builds always use
# an existing cache provided to the build, or moving logic into the tool.
FLUTTER_UNPACK_ARGS=--target-platform=linux-x64 \
	--cache-dir="$(FLUTTER_CACHE_DIR)"
ifneq ($(strip $(LOCAL_ENGINE)),)
FLUTTER_UNPACK_ARGS+= --local-engine="$(LOCAL_ENGINE)"
endif
ifneq ($(strip $(FLUTTER_ENGINE)),)
FLUTTER_UNPACK_ARGS+= --local-engine-src-path="$(FLUTTER_ENGINE)"
endif

# Add relevant code from the wrapper library, which is intended to be statically
# built into the plugin.
# Use abspath for the wrapper root, which can contain relative paths; the
# intermediate build files will be based on the source path, which will cause
# issues if they start with one or more '../'s.
WRAPPER_ROOT=$(abspath $(FLUTTER_CACHE_DIR)/cpp_client_wrapper_glfw)
# TODO: Once JSON codec files are merged, make a PLUGIN_CODEC variable in the
# top section. For now, using JSON codec would require changes here.
WRAPPER_SOURCES= \
	$(WRAPPER_ROOT)/engine_method_result.cc \
	$(WRAPPER_ROOT)/plugin_registrar.cc \
	$(WRAPPER_ROOT)/standard_codec.cc

# Use abspath for extra sources, which may also contain relative paths (see
# note above about WRAPPER_ROOT).
SOURCES=$(PLUGIN_NAME).cc $(WRAPPER_SOURCES) $(abspath $(EXTRA_SOURCES))
PUBLIC_HEADER=$(PLUGIN_NAME).h

WRAPPER_INCLUDE_DIR=$(WRAPPER_ROOT)/include
INCLUDE_DIRS=$(FLUTTER_CACHE_DIR) $(WRAPPER_INCLUDE_DIR)

# Build settings
CXX=clang++
CXXFLAGS.release=-DNDEBUG
CXXFLAGS=-std=c++14 -Wall -Werror -fPIC -fvisibility=hidden \
	-DFLUTTER_PLUGIN_IMPL $(CXXFLAGS.$(BUILD)) $(EXTRA_CXXFLAGS)
CPPFLAGS=$(patsubst %,-I%,$(INCLUDE_DIRS)) $(EXTRA_CPPFLAGS)
LDFLAGS=-shared -L$(FLUTTER_CACHE_DIR) -l$(FLUTTER_LIB_NAME) $(EXTRA_LDFLAGS)

# Final output files that will be used by applications.
LIBRARY_OUT=$(OUT_DIR)/lib$(PLUGIN_NAME).so
HEADER_OUT=$(OUT_DIR)/include/$(PUBLIC_HEADER)

# Intermediate files.
OBJ_FILES=$(SOURCES:%.cc=$(OBJ_DIR)/%.o)
DEPENDENCY_FILES=$(OBJ_FILES:%.o=%.d)

# Targets

.PHONY: all
all: $(PLUGIN_NAME)

.PHONY: $(PLUGIN_NAME)
$(PLUGIN_NAME) : $(LIBRARY_OUT) $(HEADER_OUT)

$(LIBRARY_OUT): $(OBJ_FILES)
	mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $^ $(LDFLAGS) -o $@

$(HEADER_OUT): $(PUBLIC_HEADER)
	mkdir -p $(@D)
	cp $< $@

$(WRAPPER_SOURCES) $(FLUTTER_LIB): | sync

# This is a phony target because the flutter tool cannot describe
# its inputs and outputs yet.
.PHONY: sync
sync:
	$(FLUTTER_BIN) unpack $(FLUTTER_UNPACK_ARGS)

-include $(DEPENDENCY_FILES)

$(OBJ_DIR)/%.o : %.cc | sync
	mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -MMD -c $< -o $@

.PHONY: clean
clean:
	rm -f $(LIBRARY_OUT) $(HEADER_OUT)
	rm -rf $(PLUGINOUT_DIR)

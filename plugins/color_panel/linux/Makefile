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

# This Makefile serves as an example of building a plugin using Make.
# It is not actually used in the normal build process, since GN is used
# to build this project's plugins.

# Example-specific variables.
# To modify this Makefile for a different plugin, these are the values
# that are mostly likely to need to be changed.

# The location of the flutter-desktop-embedding repository.
FDE_ROOT=$(CURDIR)/../../..
# The filename of the plugin library to build.
LIBRARY_OUT=libflutter_embedder_color_panel.so
# The C++ code for the plugin.
COMMON_DIR=$(CURDIR)/../common
HEADERS=$(shell find include/ $(COMMON_DIR)/ -type f -name '*.h')
SOURCES=$(shell find src/ $(COMMON_DIR)/ -type f -name '*.cc')
# The include path(s) needed by your plugin code, other than for the
# embedder library headers. This project uses project-root-relative
# paths, so only includes the project root.
PLUGIN_INCLUDE_DIR=$(FDE_ROOT)
# System-level shared libraries used by your plugin.
LIBRARY_DEPENDENCIES=gtk+-3.0


# For dependency on the embedder shared library.
GN_OUT_DIR=$(FDE_ROOT)/out
EMBEDDER_LIBRARY_HEADER_DIR=$(GN_OUT_DIR)/include
EMBEDDER_LIBRARY_DIR=$(GN_OUT_DIR)
EMBEDDER_LIB_NAME=flutter_embedder
EMBEDDER_LIB_FILE=$(EMBEDDER_LIBRARY_DIR)/lib$(EMBEDDER_LIB_NAME).so

# Tools
TOOLS_DIR=$(FDE_ROOT)/tools
GN_WRAPPER=$(TOOLS_DIR)/gn_dart
NINJA_BIN=ninja


CXX=g++ -std=c++14
CXXFLAGS= -Wall -Werror -shared -fPIC -fvisibility=hidden \
	-I$(PLUGIN_INCLUDE_DIR) \
	-I$(EMBEDDER_LIBRARY_HEADER_DIR) \
	-DCOLOR_PANEL_PLUGIN_IMPL \
	$(shell pkg-config --cflags $(LIBRARY_DEPENDENCIES))
LDFLAGS= -L$(EMBEDDER_LIBRARY_DIR) \
	$(shell pkg-config --libs $(LIBRARY_DEPENDENCIES)) \
	-l$(EMBEDDER_LIB_NAME) \
	-Wl,-rpath=$(EMBEDDER_LIBRARY_DIR)

.PHONY: all
all: $(LIBRARY_OUT)
$(LIBRARY_OUT): $(SOURCES) $(HEADERS) $(EMBEDDER_LIB_FILE)
	$(CXX) $(CXXFLAGS) $(SOURCES) $(LDFLAGS) -o $@

$(EMBEDDER_LIB_FILE): | gnbuild

.PHONY: gnbuild
gnbuild: $(GN_OUT_DIR)
	$(NINJA_BIN) -C $(GN_OUT_DIR) $(FLUTTER_EMBEDDER_LIB_NAME) $(PLUGIN_NAMES)

$(GN_OUT_DIR):
	$(GN_WRAPPER) gen $(GN_OUT_DIR)

.PHONY: clean
clean:
	rm -f $(LIBRARY_OUT)

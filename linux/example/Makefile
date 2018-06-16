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

FLUTTER_EMBEDDER_LIB=flutter_embedder
FLUTTER_EXAMPLE_DIR=../../example_flutter
FLUTTER_BIN_FROM_EXAMPLE_DIR=../../flutter/bin/flutter
BIN_OUT=flutter_embedder_example

PLUGINS=color_panel file_chooser
FLUTTER_EMBEDDER_LIB_DIR=$(CURDIR)/../library
PLUGIN_DIRS=$(patsubst %,$(CURDIR)/../../plugins/%/linux,$(PLUGINS))
LIBRARY_DIRS=$(FLUTTER_EMBEDDER_LIB_DIR) $(PLUGIN_DIRS)

CXX=g++ -std=c++14
CXXFLAGS=-Wall -Werror $(shell pkg-config --cflags jsoncpp)
CPPFLAGS=$(patsubst %,-I%/include,$(LIBRARY_DIRS))
# TODO: Make the Linux example build a standalone directory with
# the binary and its dependencies (including Flutter resources),
# suitable for relocating, to more closely match the macOS example.
# Then only one -L/-rpath directory will be necessary.
LDFLAGS=$(patsubst %,-L%,$(LIBRARY_DIRS)) \
	-lglfw \
	$(shell pkg-config --libs jsoncpp) \
	-l$(FLUTTER_EMBEDDER_LIB) \
	$(patsubst %,-lflutter_embedder_%,$(PLUGINS)) \
	-Wl,-rpath=$(subst $(eval) ,:,$(LIBRARY_DIRS))

LIBRARIES=$(CURDIR)/../library/lib$(FLUTTER_EMBEDDER_LIB).so \
	$(wildcard $(PLUGIN_DIRS)/*.so)
SOURCES=flutter_embedder_example.cc

.PHONY: all
all: $(FLUTTER_EXAMPLE_DIR)/build $(BIN_OUT)

.PHONY: $(FLUTTER_EXAMPLE_DIR)/build
$(FLUTTER_EXAMPLE_DIR)/build:
	cd $(FLUTTER_EXAMPLE_DIR); \
	$(FLUTTER_BIN_FROM_EXAMPLE_DIR) build bundle

$(BIN_OUT): $(SOURCES) $(LIBRARIES)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(SOURCES) $(LDFLAGS) -o $@

.PHONY: clean
clean:
	rm -f $(BIN_OUT); \
	cd $(FLUTTER_EXAMPLE_DIR); \
	$(FLUTTER_BIN_FROM_EXAMPLE_DIR) clean

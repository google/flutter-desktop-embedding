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

# Before editing these, make sure you have read the documentation on how to
# build the flutter engine here:
# https://github.com/flutter/engine/blob/master/CONTRIBUTING.md
#
# $(FLUTTER_ENGINE_PATH) is the variable pointing to the git checkout of the
# flutter engine, under the assumption that you have already built it. Here,
# the flutter engine path is relative to
# `flutter-desktop-embedding/example_flutter`, as this Makefile will build that
# application during the build process.
#
# This variable will be used when building `example_flutter/` to pass the
# `--local-engine-src-path` flag to the flutter binary.
FLUTTER_ENGINE_PATH=../../engine

# See above regarding building the flutter engine before editing these
# variables.
#
# $(FLUTTER_ENGINE_BUILD) refers to the `gn` configuration used to build the
# engine. When running `gn --unoptimized` to generate the build configuration,
# the variable should be set (as it is now) to `host_debug_unopt`. If building
# with the flags `--runtime-mode release`, then this variable will be set to
# `host_release`.
#
# A simple way to figure out how to set this flag is to check the output of `gn`
# and then set $(FLUTTER_ENGINE_BUILD) to be the name of the directory after `out/`
#
# Example output:
#
#```
# $ ./src/flutter/gn --unoptimized
# gn gen --check in out/host_debug_unopt
# Done. Made 385 Targets from 168 files in 379ms
#```
#
# From the above, you should then set this flag to `host_debug_unopt`.
FLUTTER_ENGINE_BUILD=host_debug_unopt

FLUTTER_ENGINE_SRC=$(FLUTTER_ENGINE_PATH)/src
FLUTTER_EMBEDDER_LIB=flutter_embedder
FLUTTER_EXAMPLE_DIR=../../example_flutter
FLUTTER_BIN_FROM_EXAMPLE_DIR=../../flutter/bin/flutter
BIN_OUT=flutter_embedder_example
CXX=g++ -std=c++0x
CXXFLAGS=-Wall -Werror
CPPFLAGS=-I$(CURDIR)/../library/include
LDFLAGS=-L$(CURDIR)/../library/ \
	-lglfw \
	-lGL \
	-l$(FLUTTER_EMBEDDER_LIB) \
	-Wl,-rpath=$(CURDIR)/../library/

LIBRARIES=$(CURDIR)/../library/lib$(FLUTTER_EMBEDDER_LIB).so
SOURCES=flutter_embedder_example.cc

.PHONY: all
all: $(FLUTTER_EXAMPLE_DIR)/build $(BIN_OUT)

$(FLUTTER_EXAMPLE_DIR)/build:
	cd $(FLUTTER_EXAMPLE_DIR); \
	$(FLUTTER_BIN_FROM_EXAMPLE_DIR) build flx \
		--local-engine-src-path=$(FLUTTER_ENGINE_SRC) \
		--local-engine=$(FLUTTER_ENGINE_BUILD);

$(BIN_OUT): $(SOURCES) $(LIBRARIES)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(LDFLAGS) $(SOURCES) -o $@

.PHONY: clean
clean:
	rm -f $(BIN_OUT); \
	cd $(FLUTTER_EXAMPLE_DIR); \
	$(FLUTTER_BIN_FROM_EXAMPLE_DIR) clean

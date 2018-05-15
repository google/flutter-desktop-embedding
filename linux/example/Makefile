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
include ../engine.mk

FLUTTER_EMBEDDER_LIB=flutter_embedder
FLUTTER_EXAMPLE_DIR=../../example_flutter
FLUTTER_BIN_FROM_EXAMPLE_DIR=../../flutter/bin/flutter
BIN_OUT=flutter_embedder_example
CXX=g++ -std=c++0x
CXXFLAGS=-Wall -Werror $(shell pkg-config --cflags jsoncpp)
CPPFLAGS=-I$(CURDIR)/../library/include
LDFLAGS=-L$(CURDIR)/../library/ \
	-lglfw \
	$(shell pkg-config --libs jsoncpp) \
	-l$(FLUTTER_EMBEDDER_LIB) \
	-Wl,-rpath=$(CURDIR)/../library/

LIBRARIES=$(CURDIR)/../library/lib$(FLUTTER_EMBEDDER_LIB).so
SOURCES=flutter_embedder_example.cc

.PHONY: all
all: $(FLUTTER_EXAMPLE_DIR)/build $(BIN_OUT)

$(FLUTTER_EXAMPLE_DIR)/build: $(LIBRARIES)
	cd $(FLUTTER_EXAMPLE_DIR); \
	$(FLUTTER_BIN_FROM_EXAMPLE_DIR) build bundle \
		--local-engine-src-path=$(FLUTTER_ENGINE_SYNC) \
		--local-engine=$(FLUTTER_ENGINE_BUILD);

$(BIN_OUT): $(SOURCES) $(LIBRARIES)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(SOURCES) $(LDFLAGS) -o $@

.PHONY: clean
clean:
	rm -f $(BIN_OUT); \
	cd $(FLUTTER_EXAMPLE_DIR); \
	$(FLUTTER_BIN_FROM_EXAMPLE_DIR) clean

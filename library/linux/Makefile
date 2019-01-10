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
FLUTTER_ENGINE_LIB_NAME=flutter_engine
FLUTTER_ENGINE_LIB_FILE=lib$(FLUTTER_ENGINE_LIB_NAME).so
FLUTTER_ENGINE_HEADER=flutter_embedder.h
# Use an include/ directory for the engine header for consistency.
FLUTTER_ENGINE_HEADER_DIR=$(CURDIR)/include
PROJECT_ROOT=../..
TOOLS_DIR=$(PROJECT_ROOT)/tools
ENGINE_UPDATER=$(TOOLS_DIR)/update_flutter_engine
FLUTTER_DIR=$(shell "$(TOOLS_DIR)/flutter_location")
LIBRARY_OUT=libflutter_embedder.so
CXX=g++ -std=c++14
CXXFLAGS= -Wall -Werror -shared -fPIC -fvisibility=hidden \
	-I$(PROJECT_ROOT) \
	-I$(PROJECT_ROOT)/library/include \
	-I$(FLUTTER_ENGINE_HEADER_DIR) \
	-DFLUTTER_DESKTOP_EMBEDDING_IMPL \
	$(shell pkg-config --cflags gtk+-3.0 epoxy x11 jsoncpp glfw3)
LDFLAGS= -L$(CURDIR) \
	$(shell pkg-config --libs gtk+-3.0 epoxy x11 jsoncpp glfw3) \
	-lGL -l$(FLUTTER_ENGINE_LIB_NAME) \
	-Wl,-rpath=$(CURDIR)


LIBRARIES=$(FLUTTER_ENGINE_LIB_FILE)
HEADERS=$(shell find $(PROJECT_ROOT)/library/include/ -type f -name '*.h') \
	$(FLUTTER_ENGINE_HEADER_DIR)/$(FLUTTER_ENGINE_HEADER)
SOURCES=$(shell find $(PROJECT_ROOT)/library/common/ -type f -name '*.cc')

.PHONY: all
all: $(LIBRARY_OUT)

$(LIBRARY_OUT): $(SOURCES) $(HEADERS) $(LIBRARIES)
	$(CXX) $(CXXFLAGS) $(SOURCES) $(LDFLAGS) -o $@

# Ideally this would use a .PHONY target since the script knows when it
# needs to re-run, but that causes the embedder to need to re-link every
# time. Instead, this duplicates the dependency information that the script
# already has, and makes things slightly more fragile, in exchange for
# avoiding unnecessary relinks.
$(FLUTTER_ENGINE_LIB_FILE) $(FLUTTER_ENGINE_HEADER_DIR)/$(FLUTTER_ENGINE_HEADER): \
		$(FLUTTER_DIR)/bin/internal/engine.version
	$(ENGINE_UPDATER) ./
	if [ -f $(FLUTTER_ENGINE_HEADER) ]; then \
		mkdir -p $(FLUTTER_ENGINE_HEADER_DIR) && \
		mv $(FLUTTER_ENGINE_HEADER) $(FLUTTER_ENGINE_HEADER_DIR)/; \
		fi

.PHONY: clean
clean:
	rm -f $(LIBRARY_OUT)

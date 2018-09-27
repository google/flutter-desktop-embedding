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
LIBRARY_OUT=libflutter_embedder_menubar.so

# For dependency on the embedder shared library.
EMBEDDER_LIBRARY_DIR=$(CURDIR)/../../../linux/library
EMBEDDER_LIB_NAME=flutter_engine
EMBEDDER_LIB_FILE=$(EMBEDDER_LIBRARY_DIR)/lib$(EMBEDDER_LIB_NAME).so

COMMON_DIR=$(CURDIR)/../common

CXX=g++ -std=c++14
CXXFLAGS= -Wall -Werror -shared -fPIC \
	-I$(CURDIR)/include \
	-I$(COMMON_DIR) \
	-I$(EMBEDDER_LIBRARY_DIR)/include \
	$(shell pkg-config --cflags gtk+-3.0 jsoncpp)
LDFLAGS= -L$(EMBEDDER_LIBRARY_DIR) \
	$(shell pkg-config --libs gtk+-3.0 jsoncpp) \
	-l$(EMBEDDER_LIB_NAME) \
	-Wl,-rpath=$(EMBEDDER_LIBRARY_DIR)

LIBRARIES=$(EMBEDDER_LIB_FILE)
HEADERS=$(shell find include/ $(COMMON_DIR)/ -type f -name '*.h')
SOURCES=$(shell find src/ $(COMMON_DIR)/ -type f -name '*.cc')

.PHONY: all
all: $(LIBRARY_OUT)
$(LIBRARY_OUT): $(SOURCES) $(HEADERS) $(LIBRARIES)
	$(CXX) $(CXXFLAGS) $(SOURCES) $(LDFLAGS) -o $@

.PHONY: clean
clean:
	rm -f $(LIBRARY_OUT)

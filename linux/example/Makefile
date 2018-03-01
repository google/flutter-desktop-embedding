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
BIN_OUT=flutter_embedder_example
CXX=g++ -std=c++0x
CXXFLAGS= \
	-Wall -Werror \
	-I$(CURDIR)/../library/include \
	-L$(CURDIR)/../library \
	-lGL -lglfw -l$(FLUTTER_EMBEDDER_LIB) \
	-Wl,-rpath=$(CURDIR)/../library \

LIBRARIES=$(CURDIR)/../library/lib$(FLUTTER_EMBEDDER_LIB).so
SOURCES=flutter_embedder_example.cc

all: $(BIN_OUT)

$(BIN_OUT): $(SOURCES) $(LIBRARIES)
	$(CXX) $(CXXFLAGS) -o $@ $(SOURCES)

.PHONY: clean
clean:
	rm -f $(BIN_OUT)

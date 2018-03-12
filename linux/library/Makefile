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
FLUTTER_ENGINE_LIB=flutter_engine
LIBRARY_OUT=libflutter_embedder.so
CXX=g++ -std=c++0x
CXXFLAGS= \
	-Wall -Werror -shared -fPIC \
	-L$(CURDIR) \
	-lGL -lglfw -l$(FLUTTER_ENGINE_LIB) \
	-Wl,-rpath=$(CURDIR) \

LIBRARIES=lib$(FLUTTER_ENGINE_LIB).so
HEADERS=$(wildcard include/*.h)
SOURCES=flutter_embedder.cc

.PHONY: all
all: $(LIBRARY_OUT)

$(LIBRARY_OUT): $(SOURCES) $(HEADERS) $(LIBRARIES)
	$(CXX) $(SOURCES) $(CXXFLAGS) -o $@

.PHONY: clean
clean:
	rm -f $(LIBRARY_OUT)

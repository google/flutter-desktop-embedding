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
CXX=g++ -std=c++0x
CXXFLAGS= \
	-Wall -Werror \
	-I$(CURDIR) \
	-L$(CURDIR) \
	-lGL -lglfw -l$(FLUTTER_ENGINE_LIB) \
	-Wl,-rpath=$(CURDIR) \

all: flutter_embedder

flutter_embedder: main.cc lib$(FLUTTER_ENGINE_LIB).so
	$(CXX) $(CXXFLAGS) main.cc -o $@

.PHONY: clean
clean:
	rm -f flutter_embedder

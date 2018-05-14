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
include engine.mk

ENGINE_LIBRARY=library/libflutter_engine.so
ENGINE_HEADER=library/include/embedder.h
TARGETS=all
SUBDIRS=library example

$(TARGETS): $(SUBDIRS)
$(SUBDIRS): $(ENGINE_LIBRARY) $(ENGINE_HEADER)
	$(MAKE) -C $@ $(MAKECMDGOALS)

# Cleans all of this directory AND the engine directory. This is written for
# convenience in the event that the flutter engine is causing errors (mostly
# likely due to being out of sync).
clean_all: clean
	rm -f $(ENGINE_LIBRARY)
	rm -f $(ENGINE_HEADER)
	rm -f $(FLUTTER_ENGINE_GCLIENT) $(FLUTTER_ENGINE_ROOT_DIR)/.gclient_entries
	rm -rf $(FLUTTER_ENGINE_SYNC)
	rm -f $(ENGINE_LIBRARY)
	rm -f $(ENGINE_HEADER)

# Only cleans this folder (library and example)
clean:
	make -C library clean
	make -C example clean

# Example must be built after library. This prevents accidentally building the
# two in parallel in the event that someone supplies the -j flag to `make`.
example: library

# Copies library into the linux embedder library/ directory.
$(ENGINE_LIBRARY): $(FLUTTER_ENGINE_LIB_PATH)
	cp $(FLUTTER_ENGINE_LIB_PATH) $(dir $(ENGINE_LIBRARY))

# Copies the embedder header into the include/ directory.
$(ENGINE_HEADER):
	cp $(FLUTTER_ENGINE_HEADER) $(dir $(ENGINE_HEADER))

$(FLUTTER_ENGINE_LIB_PATH): $(FLUTTER_ENGINE_NINJA_CONFIG)

# Builds libflutter_engine.so
$(FLUTTER_ENGINE_NINJA_CONFIG): $(FLUTTER_ENGINE_GN_TESTFILE)
	$(FLUTTER_ENGINE_NINJA) $(FLUTTER_ENGINE_NINJA_ARGS)

# Generates ninja files for building.
$(FLUTTER_ENGINE_GN_TESTFILE): $(FLUTTER_ENGINE_SYNC)
	$(FLUTTER_ENGINE_GN) $(FLUTTER_ENGINE_GN_ARGS)

# Runs gclient sync.
$(FLUTTER_ENGINE_SYNC): $(FLUTTER_ENGINE_GCLIENT)
	cd $(FLUTTER_ENGINE_ROOT) && $(GCLIENT) $(GCLIENT_ARGS)

$(FLUTTER_ENGINE_GCLIENT): $(FLUTTER_ENGINE_GCLIENT_MANIFEST)
	cp $(FLUTTER_ENGINE_GCLIENT_MANIFEST) $(FLUTTER_ENGINE_GCLIENT)

.PHONY: $(TARGETS) $(SUBDIRS) clean_all clean

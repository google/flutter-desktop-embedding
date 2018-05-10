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
# $(FLUTTER_ENGINE_ROOT) is the variable pointing to the git checkout of the
# flutter engine. Here, the flutter engine path is relative to
# `flutter-desktop-embedding/linux`
#
# This variable will be used when building `example_flutter/` to pass the
# `--local-engine-src-path` flag to the flutter binary.
FLUTTER_ENGINE_ROOT=../../engine

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
FLUTTER_ENGINE_SYNC=$(FLUTTER_ENGINE_ROOT)/src
FLUTTER_ENGINE_LIB_PATH= \
	$(FLUTTER_ENGINE_ROOT)/src/out/$(FLUTTER_ENGINE_BUILD)/libflutter_engine.so
FLUTTER_ENGINE_GCLIENT=$(FLUTTER_ENGINE_ROOT)/.gclient
FLUTTER_ENGINE_GCLIENT_MANIFEST=gclient_manifest.gclient
FLUTTER_ENGINE_LIB_DIR:=$(dir $(FLUTTER_ENGINE_LIB_PATH))
FLUTTER_ENGINE_GN_TESTFILE=$(FLUTTER_ENGINE_LIB_DIR)/args.gn
FLUTTER_ENGINE_GN=$(FLUTTER_ENGINE_SYNC)/flutter/tools/gn
FLUTTER_ENGINE_GN_ARGS=--unoptimized
FLUTTER_ENGINE_NINJA_CONFIG=$(FLUTTER_ENGINE_LIB_DIR)/build.ninja
FLUTTER_ENGINE_NINJA=$(FLUTTER_ENGINE_SYNC)/buildtools/ninja
# Builds the bare minimum requirements in order to build a flutter application.
FLUTTER_ENGINE_NINJA_ARGS=-C $(FLUTTER_ENGINE_LIB_DIR) \
	flutter_engine \
	dart-sdk/bin/dart \
	gen/frontend_server.dart.snapshot
FLUTTER_ENGINE_HEADER=$(FLUTTER_ENGINE_ROOT)/shell/platform/embedder/embedder.h
GCLIENT=gclient
GCLIENT_ARGS=sync


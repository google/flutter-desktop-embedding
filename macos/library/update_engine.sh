#!/bin/bash -e
#
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

# This script downloads a specific version of FlutterEmbedder.framework, which
# is the prebuild Flutter engine framework for macOS. By default it pulls the
# version to fetch from a Flutter tree, but that can be overridden by
# $FLUTTER_ENGINE_VERSION_OVERRIDE.
# 
# Currently the script assumes that the Flutter tree is in the same directory
# as this respository, and that the downloaded file should be stored in a
# "flutter_engine_framework" directory next to both of them.
# TODO: Make the script more flexible about paths.

if [ "$SRCROOT" != "" ]; then
  PROJECT_DIR="$SRCROOT"
else
  PROJECT_DIR="$(dirname "$0")"
fi
# Path to the folder containing this repository and the flutter tree (see
# note above).
REPO_PARENT="${PROJECT_DIR}/../../.."
FLUTTER_ENGINE_VERSION_FILE=flutter/bin/internal/engine.version
# By default, match the embedder engine version to the current flutter tree.
# This can be manually overridden with FLUTTER_ENGINE_VERSION_OVERRIDE (e.g.,
# to roll the embedder to a newer-but-still-compatible version).
if [ "$FLUTTER_ENGINE_VERSION_OVERRIDE" == "" ]; then
  FLUTTER_EMBEDDER_SHA=`cat $REPO_PARENT/$FLUTTER_ENGINE_VERSION_FILE`
else
  FLUTTER_EMBEDDER_SHA="${FLUTTER_ENGINE_VERSION_OVERRIDE}"
fi
# The name of the Flutter engine framework.
FRAMEWORK_FILENAME=FlutterEmbedder.framework

# Everything from here on assumes that the current path is $ENGINE_DIRECTORY.
# This avoids having to worry about paths being relative vs. absolute.
ENGINE_DIRECTORY="${REPO_PARENT}/flutter_engine_framework"
mkdir -p "$ENGINE_DIRECTORY"
cd "$ENGINE_DIRECTORY"

# TODO: Eliminate this file once https://github.com/flutter/flutter/issues/13879
# is fixed.
VERSION_STAMP_FILENAME=.last_engine_version

# Only download the framework if the version has changed.
if [ -e "${FRAMEWORK_FILENAME}" ] && [ -e "${VERSION_STAMP_FILENAME}" ]; then
  LAST_DOWNLOAD_VERSION=`cat ${VERSION_STAMP_FILENAME}`
fi

if [ "$LAST_DOWNLOAD_VERSION" != "$FLUTTER_EMBEDDER_SHA" ]; then
  FRAMEWORK_ARCHIVE_FILENAME="${FRAMEWORK_FILENAME}.zip"

  curl -O https://storage.googleapis.com/flutter_infra/flutter/${FLUTTER_EMBEDDER_SHA}/darwin-x64/$FRAMEWORK_ARCHIVE_FILENAME
  rm -rf $FRAMEWORK_FILENAME
  # Unzip twice, as the downloaded zip contains a zip file, rather than the framework.
  unzip -o $FRAMEWORK_ARCHIVE_FILENAME && unzip -o $FRAMEWORK_ARCHIVE_FILENAME -d $FRAMEWORK_FILENAME
  rm $FRAMEWORK_ARCHIVE_FILENAME

  # Record the new download version.
  echo $FLUTTER_EMBEDDER_SHA > $VERSION_STAMP_FILENAME
  echo "Downloaded $FRAMEWORK_FILENAME version '$FLUTTER_EMBEDDER_SHA'."
else
  echo "$FRAMEWORK_FILENAME version '$FLUTTER_EMBEDDER_SHA' already present."
fi

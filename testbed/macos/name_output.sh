#!/usr/bin/env bash
#
# Copyright 2019 Google LLC
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

# This script outputs the path to the app bundle that is created by
# build.sh for the given configuration ("debug" or "release").
#
# Having this file in this location, with this name, enables the current
# experimental 'flutter run' support for desktop.

# Arguments
readonly flutter_config="$1"

# Directories
readonly base_dir="$(dirname "$0")"
readonly flutter_app_dir="${base_dir}/.."
# This must match the paths in build.sh.
readonly products_dir="${flutter_app_dir}/build/macos/Build/Products"

# Xcode configuration
readonly app_name="Flutter Desktop Example"
if [[ "${flutter_config}" == "release" ]]; then
  readonly build_config="Release"
else
  readonly build_config="Debug"
fi

echo "${products_dir}/${build_config}/${app_name}.app"

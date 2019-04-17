#!/usr/bin/env bash
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

# This script does a command-line build of the Xcode project, with the
# build output in a 'macos' directory under the Flutter build directory.
#
# Having this file in this location, with this name, enables the current
# experimental 'flutter build' support for desktop.

# Arguments
readonly flutter_root="$1"
readonly flutter_config="$2"

# Directories
readonly base_dir="$(dirname "$0")"
readonly xcode_project_dir="${base_dir}"
readonly flutter_app_dir="${base_dir}/.."
# The output directory must be absolute, or Xcode will treat it as
# relative to each subproject.
output_dir="${flutter_app_dir}/build/macos"
mkdir -p "${output_dir}"
output_dir="$(cd "${output_dir}" && pwd)"

# Xcode configuration
readonly project_name="Runner"
readonly scheme_name="Runner"
if [[ "${flutter_config}" == "release" ]]; then
  readonly build_config="Release"
else
  readonly build_config="Debug"
fi

# Run the Xcode build, redirecting all output to the Flutter build
# directory.
xcodebuild -project "${xcode_project_dir}/${project_name}.xcodeproj" \
  -scheme "${scheme_name}" \
  -configuration "${build_config}" \
  -derivedDataPath "${output_dir}" \
  OBJROOT="${output_dir}/Build/Intermediates.noindex" \
  SYMROOT="${output_dir}/Build/Products" \

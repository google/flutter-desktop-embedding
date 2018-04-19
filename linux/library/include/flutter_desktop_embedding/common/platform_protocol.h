// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
#ifndef LINUX_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_COMMON_PLATFORM_PROTOCOL_H_
#define LINUX_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_COMMON_PLATFORM_PROTOCOL_H_

// Defines a set of common JSON keys for communicating with the Flutter Engine's
// platform message protocol.
namespace flutter_desktop_embedding {

static constexpr char kMethodKey[] = "method";
static constexpr char kArgumentsKey[] = "args";

}  // namespace flutter_desktop_embedding

#endif  // LINUX_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_COMMON_PLATFORM_PROTOCOL_H_

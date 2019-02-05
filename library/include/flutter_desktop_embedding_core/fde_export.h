// Copyright 2019 Google LLC
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
#ifndef LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_CORE_FDE_EXPORT_H_
#define LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_CORE_FDE_EXPORT_H_

#ifdef FLUTTER_DESKTOP_EMBEDDING_IMPL
// Add visibiilty/export annotations when building the library.

#ifdef _WIN32
#define FDE_EXPORT __declspec(dllexport)
#else
#define FDE_EXPORT __attribute__((visibility("default")))
#endif

#else

// Add import annotations when consuming the library.
#ifdef _WIN32
#define FDE_EXPORT __declspec(dllimport)
#else
#define FDE_EXPORT
#endif

#endif

#endif  // LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_CORE_FDE_EXPORT_H_

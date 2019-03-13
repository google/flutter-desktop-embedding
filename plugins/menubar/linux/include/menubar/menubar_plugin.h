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
#ifndef PLUGINS_MENUBAR_LINUX_INCLUDE_MENUBAR_MENUBAR_PLUGIN_H_
#define PLUGINS_MENUBAR_LINUX_INCLUDE_MENUBAR_MENUBAR_PLUGIN_H_

// A plugin to control a native menubar.

#include <flutter_plugin_registrar.h>

#ifdef MENUBAR_PLUGIN_IMPL
#define MENUBAR_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define MENUBAR_PLUGIN_EXPORT
#endif

#if defined(__cplusplus)
extern "C" {
#endif

MENUBAR_PLUGIN_EXPORT void MenubarRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // PLUGINS_MENUBAR_LINUX_INCLUDE_MENUBAR_MENUBAR_PLUGIN_H_

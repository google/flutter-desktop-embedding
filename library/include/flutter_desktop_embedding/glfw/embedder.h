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

#ifndef LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_GLFW_EMBEDDER_H_
#define LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_GLFW_EMBEDDER_H_

#include <memory>
#include <string>
#include <vector>

#ifdef __linux__
// Epoxy must be included before any graphics-related code.
#include <epoxy/gl.h>
#endif

#include <GLFW/glfw3.h>

#ifdef USE_FLATTENED_INCLUDES
#include "fde_export.h"
#include "plugin_registrar.h"
#else
#include "../fde_export.h"
#include "../plugin_registrar.h"
#endif

namespace flutter_desktop_embedding {

// Calls glfwInit()
//
// glfwInit() must be called in the same library as glfwCreateWindow()
FDE_EXPORT bool FlutterInit();

// Calls glfwTerminate()
//
// glfwTerminate() must be called in the same library as glfwCreateWindow()
FDE_EXPORT void FlutterTerminate();

// Creates a GLFW Window running a Flutter Application.
//
// FlutterInit() must be called prior to this function.
//
// The |assets_path| is the path to the flutter_assets folder for the Flutter
// application to be run. |icu_data_path| is the path to the icudtl.dat file
// for the version of Flutter you are using.
//
// The |arguments| are passed to the Flutter engine. See:
// https://github.com/flutter/engine/blob/master/shell/common/switches.h for
// for details. Not all arguments will apply to embedding mode.
//
// Returns a null pointer in the event of an error. The caller owns the pointer
// when it is non-null.
FDE_EXPORT GLFWwindow *CreateFlutterWindow(
    size_t initial_width, size_t initial_height, const std::string &assets_path,
    const std::string &icu_data_path,
    const std::vector<std::string> &arguments);

// Returns the PluginRegistrar to register a plugin with the given name with
// the flutter_window.
//
// The name must be unique across the application, so the recommended approach
// is to use the fully namespace-qualified name of the plugin class.
FDE_EXPORT PluginRegistrar *GetRegistrarForPlugin(
    GLFWwindow *flutter_window, const std::string &plugin_name);

// Loops on flutter window events until termination.
//
// Must be used instead of glfwWindowShouldClose as it cleans up engine state
// after termination.
//
// After this function the user must eventually call FlutterTerminate() if doing
// cleanup.
FDE_EXPORT void FlutterWindowLoop(GLFWwindow *flutter_window);

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_GLFW_EMBEDDER_H_

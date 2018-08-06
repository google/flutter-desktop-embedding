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
#ifndef LINUX_LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_EMBEDDER_H_
#define LINUX_LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_EMBEDDER_H_

// Epoxy must be included before any graphics-related code.
#include <epoxy/gl.h>

#include <GLFW/glfw3.h>

#include <memory>
#include <string>

#include "plugin.h"

namespace flutter_desktop_embedding {

// Creates a GLFW Window running a Flutter Application.
//
// glfwInit() must be called prior to this function.
//
// The arguments are to configure the paths when launching the engine. See:
// https://github.com/flutter/engine/wiki/Custom-Flutter-Engine-Embedders for
// more details on Flutter Engine embedding.
//
// Returns a null pointer in the event of an error. The caller owns the pointer
// when it is non-null.
GLFWwindow *CreateFlutterWindow(size_t initial_width, size_t initial_height,
                                const std::string &main_path,
                                const std::string &assets_path,
                                const std::string &packages_path,
                                const std::string &icu_data_path, int argc,
                                char **argv);

// Creates a GLFW Window running a Flutter Application in snapshot mode.
//
// glfwInit() must be called prior to this function.
//
// In snapshot mode the assets directory snapshot is used to run the application
// instead of the sources.
//
// The arguments are to configure the paths when launching the engine. See:
// https://github.com/flutter/engine/wiki/Custom-Flutter-Engine-Embedders for
// more details on Flutter Engine embedding.
//
// Returns a null pointer in the event of an error. The caller owns the pointer
// when it is non-null.
GLFWwindow *CreateFlutterWindowInSnapshotMode(size_t initial_width,
                                              size_t initial_height,
                                              const std::string &assets_path,
                                              const std::string &icu_data_path,
                                              int argc, char **argv);

// Adds a plugin to the flutter_window.
//
// If a plugin already exists for this plugin's channel, returns false.
// Otherwise returns true.
bool AddPlugin(GLFWwindow *flutter_window, std::unique_ptr<Plugin> plugin);

// Loops on flutter window events until termination.
//
// Must be used instead of glfwWindowShouldClose as it cleans up engine state
// after termination.
//
// After this function the user must eventually call glfwTerminate() if doing
// cleanup.
void FlutterWindowLoop(GLFWwindow *flutter_window);

}  // namespace flutter_desktop_embedding

#endif  // LINUX_LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_EMBEDDER_H_

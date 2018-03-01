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
#include <cstdlib>
#include <iostream>

#include <flutter_embedder.h>

int main(int argc, char **argv) {
  // Edit this as needed.
  std::string flutter_example_root = "../../flutter/examples/flutter_gallery";
  if (!glfwInit()) {
    std::cout << "Couldn't init GLFW";
  }
  auto window = CreateFlutterWindow(
      640, 480, flutter_example_root + "/lib/main.dart",
      flutter_example_root + "/build/flutter_assets",
      flutter_example_root + "/.packages",
      "../../flutter/bin/cache/artifacts/engine/linux-x64/icudtl.dat", argc,
      argv);
  if (window == nullptr) {
    glfwTerminate();
    return EXIT_FAILURE;
  }
  FlutterWindowLoop(window);
  glfwTerminate();
  return EXIT_SUCCESS;
}

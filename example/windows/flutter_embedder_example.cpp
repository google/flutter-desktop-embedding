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

#include <iostream>
#include <vector>

#include <flutter_desktop_embedding/embedder.h>

int main(int argc, char **argv) {
  if (!flutter_desktop_embedding::FlutterInit()) {
    std::cout << "Couldn't init GLFW" << std::endl;
  }
  // Arguments for the Flutter Engine.
  std::vector<std::string> arguments;
  // First argument is argv[0] since the engine is expecting real command line
  // args.
  arguments.push_back(argv[0]);
#ifndef _DEBUG
  arguments.push_back("--dart-non-checked-mode");
#endif
  // Start the engine.
  // TODO: Make paths relative to the executable so it can be run from anywhere.
  auto window = flutter_desktop_embedding::CreateFlutterWindowInSnapshotMode(
      640, 480, "..\\..\\example\\flutter_app\\build\\flutter_assets",
      "..\\..\\library\\windows\\dependencies\\engine\\icudtl.dat", arguments);
  if (window == nullptr) {
    flutter_desktop_embedding::FlutterTerminate();
    return EXIT_FAILURE;
  }

  flutter_desktop_embedding::FlutterWindowLoop(window);
  flutter_desktop_embedding::FlutterTerminate();
  return EXIT_SUCCESS;
}

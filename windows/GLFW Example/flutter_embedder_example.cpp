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
#include <embedder.h>

int main(int argc, char **argv) {
  if(!FlutterInit()) {
    std::cout << "Couldn't init GLFW" << std::endl;
  }
  // Arguments for the Flutter Engine.
  int arg_count = 2;
  // First argument is argv[0] since the engine is expecting real command line
  // args.
  const char *args_arr[] = {
      argv[0],
      "--dart-non-checked-mode",
      NULL,
  };
  // Start the engine.
  auto window = CreateFlutterWindowInSnapshotMode(
      640, 480,
      "..\\example_flutter\\build\\flutter_assets",
      "dependencies\\engine\\icudtl.dat",
      arg_count, const_cast<char **>(args_arr));
  if (window == nullptr) {
    FlutterTerminate();
    return EXIT_FAILURE;
  }

  FlutterWindowLoop(window);
  FlutterTerminate();
  return EXIT_SUCCESS;
}
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
#include <GL/gl.h>
#include <GLFW/glfw3.h>

#include <assert.h>
#include <embedder.h>
#include <getopt.h>

#include <chrono>
#include <iostream>

static_assert(FLUTTER_ENGINE_VERSION == 1, "");

static constexpr size_t kInitialWindowWidth = 640;
static constexpr size_t kInitialWindowHeight = 480;

static void GLFWcursorPositionCallbackAtPhase(GLFWwindow *window,
                                              FlutterPointerPhase phase,
                                              double x, double y) {
  FlutterPointerEvent event = {};
  event.struct_size = sizeof(event);
  event.phase = phase;
  event.x = x;
  event.y = y;
  event.timestamp =
      std::chrono::duration_cast<std::chrono::microseconds>(
          std::chrono::high_resolution_clock::now().time_since_epoch())
          .count();
  FlutterEngineSendPointerEvent(
      reinterpret_cast<FlutterEngine>(glfwGetWindowUserPointer(window)), &event,
      1);
}

static void GLFWcursorPositionCallback(GLFWwindow *window, double x, double y) {
  GLFWcursorPositionCallbackAtPhase(window, FlutterPointerPhase::kMove, x, y);
}

static void GLFWmouseButtonCallback(GLFWwindow *window, int key, int action,
                                    int mods) {
  double x, y;
  if (key == GLFW_MOUSE_BUTTON_1 && action == GLFW_PRESS) {
    glfwGetCursorPos(window, &x, &y);
    GLFWcursorPositionCallbackAtPhase(window, FlutterPointerPhase::kDown, x, y);
    glfwSetCursorPosCallback(window, GLFWcursorPositionCallback);
  }
  if (key == GLFW_MOUSE_BUTTON_1 && action == GLFW_RELEASE) {
    glfwGetCursorPos(window, &x, &y);
    GLFWcursorPositionCallbackAtPhase(window, FlutterPointerPhase::kUp, x, y);
    glfwSetCursorPosCallback(window, nullptr);
  }
}

static void GLFWKeyCallback(GLFWwindow *window, int key, int scancode,
                            int action, int mods) {
  if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
    glfwSetWindowShouldClose(window, GLFW_TRUE);
  }
}

static void GLFWwindowSizeCallback(GLFWwindow *window, int width, int height) {
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = width;
  event.height = height;
  event.pixel_ratio = 1.0;
  FlutterEngineSendWindowMetricsEvent(
      reinterpret_cast<FlutterEngine>(glfwGetWindowUserPointer(window)),
      &event);
}

static bool GLFWMakeContextCurrent(void *user_data) {
  GLFWwindow *window = reinterpret_cast<GLFWwindow *>(user_data);
  glfwMakeContextCurrent(window);
  return true;
}

static bool GLFWClearContext(void *user_data) {
  glfwMakeContextCurrent(nullptr);
  return true;
}

static bool GLFWPresent(void *user_data) {
  GLFWwindow *window = reinterpret_cast<GLFWwindow *>(user_data);
  glfwSwapBuffers(window);
  return true;
}

static uint32_t GLFWGetActiveFbo(void *user_data) { return 0; }

// Clears the GLFW window to Material Blue-Grey.
//
// This function is primarily to fix an issue when the Flutter Engine is
// spinning up, wherein artifacts of existing windows are rendered onto the
// canvas for a few moments.
//
// This function isn't necessary, but makes starting the window much easier on
// the eyes.
static void GLFWClearCanvas(GLFWwindow *window) {
  glfwMakeContextCurrent(window);
  // This color is Material Blue Grey.
  glClearColor(236, 239, 241, 0);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glFlush();
  glfwSwapBuffers(window);
  glfwMakeContextCurrent(nullptr);
}

static bool RunFlutterEngine(GLFWwindow *window,
                             const std::string &flutter_app_directory,
                             const std::string &main_path,
                             const std::string &icu_data_path) {
  FlutterRendererConfig config = {};
  config.type = kOpenGL;
  config.open_gl.struct_size = sizeof(config.open_gl);
  config.open_gl.make_current = GLFWMakeContextCurrent;
  config.open_gl.clear_current = GLFWClearContext;
  config.open_gl.present = GLFWPresent;
  config.open_gl.fbo_callback = GLFWGetActiveFbo;
  std::string assets_path = flutter_app_directory + "/build/flutter_assets";
  std::string full_main_path = flutter_app_directory + "/" + main_path;
  std::string packages_path = flutter_app_directory + "/.packages";
  FlutterProjectArgs args = {};
  args.struct_size = sizeof(FlutterProjectArgs);
  args.assets_path = assets_path.c_str();
  args.main_path =
      main_path.empty() ? main_path.c_str() : full_main_path.c_str();
  // Packages path is ignored if main_path is empty, so this can be added in
  // as-is.
  args.packages_path = packages_path.c_str();
  args.icu_data_path = icu_data_path.c_str();
  FlutterEngine engine = nullptr;
  auto result =
      FlutterEngineRun(FLUTTER_ENGINE_VERSION, &config, &args, window, &engine);
  if (result != kSuccess || engine == nullptr) {
    return false;
  }
  GLFWClearCanvas(window);
  glfwSetWindowUserPointer(window, engine);
  GLFWwindowSizeCallback(window, kInitialWindowWidth, kInitialWindowHeight);
  return true;
}

static void printUsage(char *app_name) {
  std::cout << "Usage: " << app_name
            << " --flutter_app_directory=<path_to_dart_app_root> " << std::endl;
  std::cout << "\t\t--main_path=<path_to_main_dart_file>" << std::endl;
  std::cout << "\t\t--icu_data_path=<path_to_icu_file>" << std::endl;
  std::cout << std::endl;
  std::cout << "Required Arguments:" << std::endl;
  std::cout
      << "\t--flutter_app_directory\t Path to your flutter app's main directory"
      << std::endl;
  std::cout
      << "\t--icu_data_path\t\t Path to an icudtl.dat file. If you've built "
         "the "
      << std::endl;
  std::cout << "\t\t\t\t flutter engine source this can be found in, for "
            << std::endl;
  std::cout << "\t\t\t\t example: " << std::endl;
  std::cout
      << "\t\t\t\t <flutter_engine_root>/src/out/host_debug_unopt/icudtl.dat"
      << std::endl;
  std::cout << "Optional Arguments:" << std::endl;
  std::cout << "\t--main_path\t\t Path to the flutter app's main dart file "
               "relative "
            << std::endl;
  std::cout << "\t\t\t\t to `--flutter_app_directory` (typically lib/main.dart)"
            << std::endl;
}

int main(int argc, char **argv) {
  const struct option long_options[] = {
      {"flutter_app_directory", required_argument, nullptr, 0},
      {"main_path", required_argument, nullptr, 0},
      {"icu_data_path", required_argument, nullptr, 0},
      {0, 0, 0, 0},
  };
  std::string flutter_app_directory;
  const int flutter_app_directory_index = 0;
  std::string main_path;
  const int main_path_index = 1;
  std::string icu_data_path;
  const int icu_data_path_index = 2;

  while (true) {
    int option_index = 0;
    int opt = getopt_long(argc, argv, "", long_options, &option_index);
    if (opt == -1) {
      break;
    }
    switch (opt) {
      case 0:
        // Flag was set. Don't need to do anything.
        break;
      case '?':
        printUsage(argv[0]);
        return EXIT_FAILURE;
        break;
      default:
        printUsage(argv[0]);
        return EXIT_FAILURE;
    }
    if (option_index == flutter_app_directory_index) {
      flutter_app_directory.assign(optarg);
    }
    if (option_index == main_path_index) {
      main_path.assign(optarg);
    }
    if (option_index == icu_data_path_index) {
      icu_data_path.assign(optarg);
    }
  }
  if (flutter_app_directory.empty() || icu_data_path.empty()) {
    printUsage(argv[0]);
    return EXIT_FAILURE;
  }
  auto result = glfwInit();
  if (result != GLFW_TRUE) {
    std::cout << "Error: could not initialize GLFW" << std::endl;
    return EXIT_FAILURE;
  }
  auto window = glfwCreateWindow(kInitialWindowWidth, kInitialWindowHeight,
                                 "Flutter", NULL, NULL);
  if (window == nullptr) {
    std::cout << "Error: could not create window" << std::endl;
    return EXIT_FAILURE;
  }
  bool engine_result =
      RunFlutterEngine(window, flutter_app_directory, main_path, icu_data_path);
  if (!engine_result) {
    std::cout << "Error: unable to start Flutter Engine" << std::endl;
    return EXIT_FAILURE;
  }
  glfwSetKeyCallback(window, GLFWKeyCallback);
  glfwSetWindowSizeCallback(window, GLFWwindowSizeCallback);
  glfwSetMouseButtonCallback(window, GLFWmouseButtonCallback);
  while (!glfwWindowShouldClose(window)) {
    glfwWaitEvents();
  }
  FlutterEngineShutdown(
      reinterpret_cast<FlutterEngine>(glfwGetWindowUserPointer(window)));
  glfwDestroyWindow(window);
  glfwTerminate();
  return EXIT_SUCCESS;
}

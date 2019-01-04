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

#include "library/include/flutter_desktop_embedding/glfw/embedder.h"

#include <assert.h>
#include <algorithm>
#include <chrono>
#include <cstdlib>
#include <iostream>

#include <flutter_embedder.h>

#include "library/common/glfw/key_event_handler.h"
#include "library/common/glfw/keyboard_hook_handler.h"
#include "library/common/glfw/text_input_plugin.h"
#include "library/common/internal/plugin_handler.h"

#ifdef __linux__
// For plugin-compatible event handling (e.g., modal windows).
#include <X11/Xlib.h>
#include <gtk/gtk.h>
#endif

// GLFW_TRUE & GLFW_FALSE are introduced since libglfw-3.3,
// add definitions here to compile under the old versions.
#ifndef GLFW_TRUE
#define GLFW_TRUE 1
#endif
#ifndef GLFW_FALSE
#define GLFW_FALSE 0
#endif

static_assert(FLUTTER_ENGINE_VERSION == 1, "");

// Struct for storing state within an instance of the GLFW Window.
struct FlutterEmbedderState {
  FlutterEngine engine;
  std::unique_ptr<flutter_desktop_embedding::PluginHandler> plugin_handler;

  // plugin_handler owns these pointers. Destruction happens when this struct is
  // deleted from the heap.
  std::vector<flutter_desktop_embedding::KeyboardHookHandler *>
      keyboard_hook_handlers;

  // Handles raw key interactions from GLFW.
  // TODO: Revisit ownership model once Issue #102 is resolved.
  std::unique_ptr<flutter_desktop_embedding::KeyEventHandler> key_event_handler;

  // The screen coordinates per inch on the primary monitor. Defaults to a sane value based on pixel_ratio 1.0.
  double monitor_screen_coordinates_per_inch = 160.0;
  // The ratio of pixels per screen coordinate for the window.
  double window_pixels_per_screen_coordinate = 1.0;
};

static constexpr char kDefaultWindowTitle[] = "Flutter";

// Retrieves state bag for the window in question from the GLFWWindow.
static FlutterEmbedderState *GetSavedEmbedderState(GLFWwindow *window) {
  return reinterpret_cast<FlutterEmbedderState *>(
      glfwGetWindowUserPointer(window));
}

// When GLFW calls back to the window with a framebuffer size change, notify
// FlutterEngine about the new window metrics.
// The Flutter pixel_ratio is defined as DPI/dp.
static void GLFWFramebufferSizeCallback(GLFWwindow *window, int width_px, int height_px) {
  int width;
  glfwGetWindowSize(window, &width, nullptr);

  auto state = GetSavedEmbedderState(window);
  state->window_pixels_per_screen_coordinate = width_px / width;

  double dpi = state->window_pixels_per_screen_coordinate * state->monitor_screen_coordinates_per_inch;

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = width_px;
  event.height = height_px;
  event.pixel_ratio = dpi / 160.0;
  FlutterEngineSendWindowMetricsEvent(state->engine, &event);
}

// When GLFW calls back to the window with a cursor position move, forwards to
// FlutterEngine as a pointer event with appropriate phase.
static void GLFWCursorPositionCallbackAtPhase(GLFWwindow *window,
                                              FlutterPointerPhase phase,
                                              double x, double y) {
  auto state = GetSavedEmbedderState(window);
  FlutterPointerEvent event = {};
  event.struct_size = sizeof(event);
  event.phase = phase;
  event.x = x * state->window_pixels_per_screen_coordinate;
  event.y = y * state->window_pixels_per_screen_coordinate;
  event.timestamp =
      std::chrono::duration_cast<std::chrono::microseconds>(
          std::chrono::high_resolution_clock::now().time_since_epoch())
          .count();
  FlutterEngineSendPointerEvent(state->engine, &event, 1);
}

// Reports cursor move to the Flutter engine.
static void GLFWCursorPositionCallback(GLFWwindow *window, double x, double y) {
  GLFWCursorPositionCallbackAtPhase(window, FlutterPointerPhase::kMove, x, y);
}

// Reports mouse button press to the Flutter engine.
static void GLFWMouseButtonCallback(GLFWwindow *window, int key, int action,
                                    int mods) {
  double x, y;
  if (key == GLFW_MOUSE_BUTTON_1 && action == GLFW_PRESS) {
    glfwGetCursorPos(window, &x, &y);
    GLFWCursorPositionCallbackAtPhase(window, FlutterPointerPhase::kDown, x, y);
    glfwSetCursorPosCallback(window, GLFWCursorPositionCallback);
  }
  if (key == GLFW_MOUSE_BUTTON_1 && action == GLFW_RELEASE) {
    glfwGetCursorPos(window, &x, &y);
    GLFWCursorPositionCallbackAtPhase(window, FlutterPointerPhase::kUp, x, y);
    glfwSetCursorPosCallback(window, nullptr);
  }
}

// Passes character input events to registered handlers.
static void GLFWCharCallback(GLFWwindow *window, unsigned int code_point) {
  for (flutter_desktop_embedding::KeyboardHookHandler *handler :
       GetSavedEmbedderState(window)->keyboard_hook_handlers) {
    handler->CharHook(window, code_point);
  }
}

// Passes raw key events to registered handlers.
static void GLFWKeyCallback(GLFWwindow *window, int key, int scancode,
                            int action, int mods) {
  for (flutter_desktop_embedding::KeyboardHookHandler *handler :
       GetSavedEmbedderState(window)->keyboard_hook_handlers) {
    handler->KeyboardHook(window, key, scancode, action, mods);
  }
}

// Flushes event queue and then assigns default window callbacks.
static void GLFWAssignEventCallbacks(GLFWwindow *window) {
  glfwPollEvents();
  glfwSetKeyCallback(window, GLFWKeyCallback);
  glfwSetCharCallback(window, GLFWCharCallback);
  glfwSetMouseButtonCallback(window, GLFWMouseButtonCallback);
}

// Clears default window events.
static void GLFWClearEventCallbacks(GLFWwindow *window) {
  glfwSetKeyCallback(window, nullptr);
  glfwSetCharCallback(window, nullptr);
  glfwSetMouseButtonCallback(window, nullptr);
}

// The Flutter Engine calls out to this function when new platform messages are
// available
static void GLFWOnFlutterPlatformMessage(const FlutterPlatformMessage *message,
                                         void *user_data) {
  if (message->struct_size != sizeof(FlutterPlatformMessage)) {
    std::cerr << "Invalid message size received. Expected: "
              << sizeof(FlutterPlatformMessage) << " but received "
              << message->struct_size << std::endl;
    return;
  }

  GLFWwindow *window = reinterpret_cast<GLFWwindow *>(user_data);
  auto state = GetSavedEmbedderState(window);
  state->plugin_handler->HandleMethodCallMessage(
      message, [window] { GLFWClearEventCallbacks(window); },
      [window] { GLFWAssignEventCallbacks(window); });
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
  glClearColor(236.0 / 255.0, 239.0 / 255.0, 241.0 / 255.0, 0);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glFlush();
  glfwSwapBuffers(window);
  glfwMakeContextCurrent(nullptr);
}

// Resolves the address of the specified OpenGL or OpenGL ES
// core or extension function, if it is supported by the current context.
static void *GLFWProcResolver(void *user_data, const char *name) {
  return reinterpret_cast<void *>(glfwGetProcAddress(name));
}

// Spins up an instance of the Flutter Engine.
//
// This function launches the Flutter Engine in a background thread, supplying
// the necessary callbacks for rendering within a GLFWwindow.
//
// Returns a caller-owned pointer to the engine.
static FlutterEngine RunFlutterEngine(
    GLFWwindow *window, const std::string &main_path,
    const std::string &assets_path, const std::string &packages_path,
    const std::string &icu_data_path,
    const std::vector<std::string> &arguments) {
  std::vector<const char *> argv;
  std::transform(
      arguments.begin(), arguments.end(), std::back_inserter(argv),
      [](const std::string &arg) -> const char * { return arg.c_str(); });

  FlutterRendererConfig config = {};
  config.type = kOpenGL;
  config.open_gl.struct_size = sizeof(config.open_gl);
  config.open_gl.make_current = GLFWMakeContextCurrent;
  config.open_gl.clear_current = GLFWClearContext;
  config.open_gl.present = GLFWPresent;
  config.open_gl.fbo_callback = GLFWGetActiveFbo;
  config.open_gl.gl_proc_resolver = GLFWProcResolver;
  FlutterProjectArgs args = {};
  args.struct_size = sizeof(FlutterProjectArgs);
  args.assets_path = assets_path.c_str();
  args.main_path = main_path.c_str();
  args.packages_path = packages_path.c_str();
  args.icu_data_path = icu_data_path.c_str();
  args.command_line_argc = argv.size();
  args.command_line_argv = &argv[0];
  args.platform_message_callback = GLFWOnFlutterPlatformMessage;
  FlutterEngine engine = nullptr;
  auto result =
      FlutterEngineRun(FLUTTER_ENGINE_VERSION, &config, &args, window, &engine);
  if (result != kSuccess || engine == nullptr) {
    return nullptr;
  }
  return engine;
}

namespace flutter_desktop_embedding {

// Initialize glfw
bool FlutterInit() { return glfwInit(); }

// Tear down glfw
void FlutterTerminate() { glfwTerminate(); }

// set up embedder state and add the plugin to the plugin_handler
bool AddPlugin(GLFWwindow *flutter_window, std::unique_ptr<Plugin> plugin) {
  auto state = GetSavedEmbedderState(flutter_window);
  return state->plugin_handler->AddPlugin(std::move(plugin));
}

GLFWwindow *CreateFlutterWindowInSnapshotMode(
    size_t initial_width, size_t initial_height, const std::string &assets_path,
    const std::string &icu_data_path,
    const std::vector<std::string> &arguments) {
  return CreateFlutterWindow(initial_width, initial_height, "", assets_path, "",
                             icu_data_path, arguments);
}

GLFWwindow *CreateFlutterWindow(size_t initial_width, size_t initial_height,
                                const std::string &main_path,
                                const std::string &assets_path,
                                const std::string &packages_path,
                                const std::string &icu_data_path,
                                const std::vector<std::string> &arguments) {
#ifdef __linux__
  gtk_init(0, nullptr);
#endif
  auto window = glfwCreateWindow(initial_width, initial_height,
                                 kDefaultWindowTitle, NULL, NULL);
  if (window == nullptr) {
    return nullptr;
  }
  GLFWClearCanvas(window);
  auto engine = RunFlutterEngine(window, main_path, assets_path, packages_path,
                                 icu_data_path, arguments);
  if (engine == nullptr) {
    glfwDestroyWindow(window);
    return nullptr;
  }

  FlutterEmbedderState *state = new FlutterEmbedderState();
  state->plugin_handler = std::make_unique<PluginHandler>(engine);
  state->engine = engine;

  state->key_event_handler =
      std::make_unique<KeyEventHandler>(state->plugin_handler.get());
  state->keyboard_hook_handlers.push_back(state->key_event_handler.get());
  auto input_plugin = std::make_unique<TextInputPlugin>();
  state->keyboard_hook_handlers.push_back(input_plugin.get());

  glfwSetWindowUserPointer(window, state);

  AddPlugin(window, std::move(input_plugin));

  auto primary_monitor = glfwGetPrimaryMonitor();
  auto primar_monitor_mode = glfwGetVideoMode(primary_monitor);
  int primary_monitor_width_mm;
  glfwGetMonitorPhysicalSize(primary_monitor, &primary_monitor_width_mm, nullptr);
  state->monitor_screen_coordinates_per_inch = primar_monitor_mode->width / (primary_monitor_width_mm/25.4);

  int width_px, height_px;
  glfwGetFramebufferSize(window, &width_px, &height_px);
  glfwSetFramebufferSizeCallback(window, GLFWFramebufferSizeCallback);
  GLFWFramebufferSizeCallback(window, width_px, height_px);

  GLFWAssignEventCallbacks(window);
  return window;
}

void FlutterWindowLoop(GLFWwindow *flutter_window) {
#ifdef __linux__
  // Necessary for GTK thread safety.
  XInitThreads();
#endif
  while (!glfwWindowShouldClose(flutter_window)) {
#ifdef __linux__
    glfwPollEvents();
    if (gtk_events_pending()) {
      gtk_main_iteration();
    }
#else
    glfwWaitEvents();
#endif
    // TODO(awdavies): This will be deprecated soon.
    __FlutterEngineFlushPendingTasksNow();
  }
  auto state = GetSavedEmbedderState(flutter_window);
  FlutterEngineShutdown(state->engine);
  delete state;
  glfwDestroyWindow(flutter_window);
}

}  // namespace flutter_desktop_embedding

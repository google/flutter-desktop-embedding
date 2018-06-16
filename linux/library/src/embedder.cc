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
#include <flutter_desktop_embedding/embedder.h>

#include <X11/Xlib.h>
#include <assert.h>
#include <gtk/gtk.h>
#include <json/json.h>

#include <chrono>
#include <cstdlib>
#include <iostream>
#include <memory>
#include <string>

#include <flutter_desktop_embedding/channels.h>
#include <flutter_desktop_embedding/input/keyboard_hook_handler.h>
#include <flutter_desktop_embedding/plugin_handler.h>
#include <flutter_desktop_embedding/text_input_plugin.h>
#include <flutter_embedder.h>

static_assert(FLUTTER_ENGINE_VERSION == 1, "");

// Struct for storing state within an instance of the GLFW Window.
struct FlutterEmbedderState {
  FlutterEngine engine;
  std::unique_ptr<flutter_desktop_embedding::PluginHandler> plugin_handler;

  // plugin_handler owns these pointers. Destruction happens when this struct is
  // deleted from the heap.
  std::vector<flutter_desktop_embedding::KeyboardHookHandler *>
      keyboard_hook_handlers;
};

static constexpr char kDefaultWindowTitle[] = "Flutter";

// Callback forward declarations.
static void GLFWKeyCallback(GLFWwindow *window, int key, int scancode,
                            int action, int mods);
static void GLFWCharCallback(GLFWwindow *window, unsigned int code_point);
static void GLFWmouseButtonCallback(GLFWwindow *window, int key, int action,
                                    int mods);

static FlutterEmbedderState *GetSavedEmbedderState(GLFWwindow *window) {
  return reinterpret_cast<FlutterEmbedderState *>(
      glfwGetWindowUserPointer(window));
}

// Flushes event queue and then assigns default window callbacks.
static void GLFWAssignEventCallbacks(GLFWwindow *window) {
  glfwPollEvents();
  glfwSetKeyCallback(window, GLFWKeyCallback);
  glfwSetCharCallback(window, GLFWCharCallback);
  glfwSetMouseButtonCallback(window, GLFWmouseButtonCallback);
}

// Clears default window events.
static void GLFWClearEventCallbacks(GLFWwindow *window) {
  glfwSetKeyCallback(window, nullptr);
  glfwSetCharCallback(window, nullptr);
  glfwSetMouseButtonCallback(window, nullptr);
}

static void GLFWwindowSizeCallback(GLFWwindow *window, int width, int height) {
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = width;
  event.height = height;
  event.pixel_ratio = 1.0;
  auto state = GetSavedEmbedderState(window);
  FlutterEngineSendWindowMetricsEvent(state->engine, &event);
}

static void GLFWOnFlutterPlatformMessage(const FlutterPlatformMessage *message,
                                         void *user_data) {
  if (message->struct_size != sizeof(FlutterPlatformMessage)) {
    std::cerr << "Invalid message size received. Expected: "
              << sizeof(FlutterPlatformMessage) << " but received "
              << message->struct_size << std::endl;
    return;
  }
  GLFWwindow *window = reinterpret_cast<GLFWwindow *>(user_data);
  Json::CharReaderBuilder reader_builder;
  std::unique_ptr<Json::CharReader> parser(reader_builder.newCharReader());
  Json::Value json;
  std::string parse_errors;
  auto raw_message = reinterpret_cast<const char *>(message->message);
  bool parsing_successful = parser->parse(
      raw_message, raw_message + message->message_size, &json, &parse_errors);
  if (!parsing_successful) {
    std::cerr << "Unable to parse platform message" << std::endl
              << parse_errors << std::endl;
    return;
  }
  auto state = GetSavedEmbedderState(window);
  std::string channel(message->channel);
  std::unique_ptr<flutter_desktop_embedding::MethodCall> method_call =
      flutter_desktop_embedding::MethodCall::CreateFromMessage(json);
  auto result = std::make_unique<flutter_desktop_embedding::JsonMethodResult>(
      state->engine, message->response_handle);
  state->plugin_handler->HandleMethodCall(
      channel, *method_call, std::move(result),
      [window] { GLFWClearEventCallbacks(window); },
      [window] { GLFWAssignEventCallbacks(window); });
}

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
  auto state = GetSavedEmbedderState(window);
  FlutterEngineSendPointerEvent(state->engine, &event, 1);
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

static void GLFWCharCallback(GLFWwindow *window, unsigned int code_point) {
  for (flutter_desktop_embedding::KeyboardHookHandler *handler :
       GetSavedEmbedderState(window)->keyboard_hook_handlers) {
    handler->CharHook(window, code_point);
  }
}

static void GLFWKeyCallback(GLFWwindow *window, int key, int scancode,
                            int action, int mods) {
  for (flutter_desktop_embedding::KeyboardHookHandler *handler :
       GetSavedEmbedderState(window)->keyboard_hook_handlers) {
    handler->KeyboardHook(window, key, scancode, action, mods);
  }
  if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
    glfwSetWindowShouldClose(window, GLFW_TRUE);
  }
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
  glClearColor(0.92549, 0.93725, 0.9451, 0);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glFlush();
  glfwSwapBuffers(window);
  glfwMakeContextCurrent(nullptr);
}

// Spins up an instance of the Flutter Engine.
//
// This function launches the Flutter Engine in a background thread, supplying
// the necessary callbacks for rendering within a GLFWwindow.
//
// Returns a caller-owned pointer to the engine.
static FlutterEngine RunFlutterEngine(GLFWwindow *window,
                                      const std::string &main_path,
                                      const std::string &assets_path,
                                      const std::string &packages_path,
                                      const std::string &icu_data_path,
                                      int argc, char **argv) {
  FlutterRendererConfig config = {};
  config.type = kOpenGL;
  config.open_gl.struct_size = sizeof(config.open_gl);
  config.open_gl.make_current = GLFWMakeContextCurrent;
  config.open_gl.clear_current = GLFWClearContext;
  config.open_gl.present = GLFWPresent;
  config.open_gl.fbo_callback = GLFWGetActiveFbo;
  FlutterProjectArgs args = {};
  args.struct_size = sizeof(FlutterProjectArgs);
  args.assets_path = assets_path.c_str();
  args.main_path = main_path.c_str();
  args.packages_path = packages_path.c_str();
  args.icu_data_path = icu_data_path.c_str();
  args.command_line_argc = argc;
  args.command_line_argv = argv;
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

bool AddPlugin(GLFWwindow *flutter_window, std::unique_ptr<Plugin> plugin) {
  auto state = GetSavedEmbedderState(flutter_window);
  plugin->set_flutter_engine(state->engine);
  return state->plugin_handler->AddPlugin(std::move(plugin));
}

GLFWwindow *CreateFlutterWindowInSnapshotMode(size_t initial_width,
                                              size_t initial_height,
                                              const std::string &assets_path,
                                              const std::string &icu_data_path,
                                              int argc, char **argv) {
  return CreateFlutterWindow(initial_width, initial_height, "", assets_path, "",
                             icu_data_path, argc, argv);
}

GLFWwindow *CreateFlutterWindow(size_t initial_width, size_t initial_height,
                                const std::string &main_path,
                                const std::string &assets_path,
                                const std::string &packages_path,
                                const std::string &icu_data_path, int argc,
                                char **argv) {
  gtk_init(0, nullptr);
  auto window = glfwCreateWindow(initial_width, initial_height,
                                 kDefaultWindowTitle, NULL, NULL);
  if (window == nullptr) {
    return nullptr;
  }
  GLFWClearCanvas(window);
  auto flutter_engine_run_result = RunFlutterEngine(
      window, main_path, assets_path, packages_path, icu_data_path, argc, argv);
  if (flutter_engine_run_result == nullptr) {
    glfwDestroyWindow(window);
    return nullptr;
  }
  FlutterEmbedderState *state = new FlutterEmbedderState();
  state->plugin_handler = std::make_unique<PluginHandler>();
  state->engine = flutter_engine_run_result;
  auto input_plugin = std::make_unique<TextInputPlugin>();
  state->keyboard_hook_handlers.push_back(input_plugin.get());

  glfwSetWindowUserPointer(window, state);

  AddPlugin(window, std::move(input_plugin));

  int width, height;
  glfwGetWindowSize(window, &width, &height);
  GLFWwindowSizeCallback(window, width, height);
  glfwSetWindowSizeCallback(window, GLFWwindowSizeCallback);
  GLFWAssignEventCallbacks(window);
  return window;
}

void FlutterWindowLoop(GLFWwindow *flutter_window) {
  // Necessary for GTK thread safety.
  XInitThreads();
  while (!glfwWindowShouldClose(flutter_window)) {
    glfwPollEvents();
    if (gtk_events_pending()) {
      gtk_main_iteration();
    }
    // TODO(awdavies): This will be deprecated soon.
    __FlutterEngineFlushPendingTasksNow();
  }
  auto state = GetSavedEmbedderState(flutter_window);
  FlutterEngineShutdown(state->engine);
  delete state;
  glfwDestroyWindow(flutter_window);
}

}  // namespace flutter_desktop_embedding

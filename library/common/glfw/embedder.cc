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

#include "library/include/flutter_desktop_embedding_core/glfw/embedder.h"

#include <assert.h>
#include <algorithm>
#include <chrono>
#include <cstdlib>
#include <iostream>

#ifdef __linux__
// Epoxy must be included before any graphics-related code.
#include <epoxy/gl.h>
#endif

#include <GLFW/glfw3.h>

#include <flutter_embedder.h>

#include "library/common/client_wrapper/src/plugin_handler.h"
#include "library/common/glfw/key_event_handler.h"
#include "library/common/glfw/keyboard_hook_handler.h"
#include "library/common/glfw/text_input_plugin.h"
#include "library/common/internal/incoming_message_dispatcher.h"

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

static constexpr double kDpPerInch = 160.0;

// Struct for storing state within an instance of the GLFW Window.
struct FlutterEmbedderState {
  // The GLFW window that owns this state object.
  GLFWwindow *window;

  // The handle to the Flutter engine instance.
  FlutterEngine engine;

  // Message dispatch manager for messages from the Flutter engine.
  std::unique_ptr<flutter_desktop_embedding::IncomingMessageDispatcher>
      message_dispatcher;

  // The helper class managing plugin registration.
  std::unique_ptr<flutter_desktop_embedding::PluginHandler> plugin_handler;

  // Handlers for keyboard events from GLFW.
  std::vector<std::unique_ptr<flutter_desktop_embedding::KeyboardHookHandler>>
      keyboard_hook_handlers;

  // The screen coordinates per inch on the primary monitor. Defaults to a sane
  // value based on pixel_ratio 1.0.
  double monitor_screen_coordinates_per_inch = kDpPerInch;
  // The ratio of pixels per screen coordinate for the window.
  double window_pixels_per_screen_coordinate = 1.0;
};

static constexpr char kDefaultWindowTitle[] = "Flutter";

// Retrieves state bag for the window in question from the GLFWWindow.
static FlutterEmbedderState *GetSavedEmbedderState(GLFWwindow *window) {
  return reinterpret_cast<FlutterEmbedderState *>(
      glfwGetWindowUserPointer(window));
}

// Converts a FlutterPlatformMessage to an equivalent FlutterEmbedderMessage.
static FlutterEmbedderMessage ConvertToEmbedderMessage(
    const FlutterPlatformMessage &engine_message) {
  FlutterEmbedderMessage embedder_message = {};
  embedder_message.struct_size = sizeof(embedder_message);
  embedder_message.channel = engine_message.channel;
  embedder_message.message = engine_message.message;
  embedder_message.message_size = engine_message.message_size;
  embedder_message.response_handle = engine_message.response_handle;
  return embedder_message;
}

// Returns the number of screen coordinates per inch for the main monitor.
// If the information is unavailable, returns a default value that assumes
// that a screen coordinate is one dp.
static double GetScreenCoordinatesPerInch() {
  auto *primary_monitor = glfwGetPrimaryMonitor();
  auto *primary_monitor_mode = glfwGetVideoMode(primary_monitor);
  int primary_monitor_width_mm;
  glfwGetMonitorPhysicalSize(primary_monitor, &primary_monitor_width_mm,
                             nullptr);
  if (primary_monitor_width_mm == 0) {
    return kDpPerInch;
  }
  return primary_monitor_mode->width / (primary_monitor_width_mm / 25.4);
}

// When GLFW calls back to the window with a framebuffer size change, notify
// FlutterEngine about the new window metrics.
// The Flutter pixel_ratio is defined as DPI/dp.
static void GLFWFramebufferSizeCallback(GLFWwindow *window, int width_px,
                                        int height_px) {
  int width;
  glfwGetWindowSize(window, &width, nullptr);

  auto state = GetSavedEmbedderState(window);
  state->window_pixels_per_screen_coordinate = width_px / width;

  double dpi = state->window_pixels_per_screen_coordinate *
               state->monitor_screen_coordinates_per_inch;
  // Limit the ratio to 1 to avoid rendering a smaller UI in standard resolution
  // monitors.
  double pixel_ratio = std::max(dpi / kDpPerInch, 1.0);

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = width_px;
  event.height = height_px;
  event.pixel_ratio = pixel_ratio;
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
  for (const auto &handler :
       GetSavedEmbedderState(window)->keyboard_hook_handlers) {
    handler->CharHook(window, code_point);
  }
}

// Passes raw key events to registered handlers.
static void GLFWKeyCallback(GLFWwindow *window, int key, int scancode,
                            int action, int mods) {
  for (const auto &handler :
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

  auto embedder_message = ConvertToEmbedderMessage(*message);
  state->message_dispatcher->HandleMessage(
      embedder_message, [window] { GLFWClearEventCallbacks(window); },
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
  glClearColor(236.0f / 255.0f, 239.0f / 255.0f, 241.0f / 255.0f, 0.0f);
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

static void GLFWErrorCallback(int error_code, const char *description) {
  std::cerr << "GLFW error " << error_code << ": " << description << std::endl;
}

// Spins up an instance of the Flutter Engine.
//
// This function launches the Flutter Engine in a background thread, supplying
// the necessary callbacks for rendering within a GLFWwindow.
//
// Returns a caller-owned pointer to the engine.
static FlutterEngine RunFlutterEngine(GLFWwindow *window,
                                      const char *assets_path,
                                      const char *icu_data_path,
                                      const char **arguments,
                                      size_t arguments_count) {
  // FlutterProjectArgs is expecting a full argv, so when processing it for
  // flags the first item is treated as the executable and ignored. Add a dummy
  // value so that all provided arguments are used.
  std::vector<const char *> argv = {"placeholder"};
  if (arguments_count > 0) {
    argv.insert(argv.end(), &arguments[0], &arguments[arguments_count]);
  }

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
  args.assets_path = assets_path;
  args.icu_data_path = icu_data_path;
  args.command_line_argc = static_cast<int>(argv.size());
  args.command_line_argv = &argv[0];
  args.platform_message_callback = GLFWOnFlutterPlatformMessage;
  FlutterEngine engine = nullptr;
  auto result =
      FlutterEngineRun(FLUTTER_ENGINE_VERSION, &config, &args, window, &engine);
  if (result != kSuccess || engine == nullptr) {
    std::cerr << "Failed to start Flutter engine: error " << result
              << std::endl;
    return nullptr;
  }
  return engine;
}

bool FlutterEmbedderInit() {
  // Before making any GLFW calls, set up a logging error handler.
  glfwSetErrorCallback(GLFWErrorCallback);
  return glfwInit();
}

void FlutterEmbedderTerminate() { glfwTerminate(); }

FlutterWindowRef FlutterEmbedderCreateWindow(
    int initial_width, int initial_height, const char *assets_path,
    const char *icu_data_path, const char **arguments, size_t argument_count) {
#ifdef __linux__
  gtk_init(0, nullptr);
#endif
  // Create the window.
  auto window = glfwCreateWindow(initial_width, initial_height,
                                 kDefaultWindowTitle, NULL, NULL);
  if (window == nullptr) {
    return nullptr;
  }
  GLFWClearCanvas(window);

  // Start the engine.
  auto engine = RunFlutterEngine(window, assets_path, icu_data_path, arguments,
                                 argument_count);
  if (engine == nullptr) {
    glfwDestroyWindow(window);
    return nullptr;
  }

  // Create an embedder state object attached to the window.
  FlutterEmbedderState *state = new FlutterEmbedderState();
  state->window = window;
  glfwSetWindowUserPointer(window, state);
  state->engine = engine;
  state->message_dispatcher =
      std::make_unique<flutter_desktop_embedding::IncomingMessageDispatcher>(
          state);
  state->plugin_handler =
      std::make_unique<flutter_desktop_embedding::PluginHandler>(state);

  // Set up the keyboard handlers.
  state->keyboard_hook_handlers.push_back(
      std::make_unique<flutter_desktop_embedding::KeyEventHandler>(
          state->plugin_handler.get()));
  state->keyboard_hook_handlers.push_back(
      std::make_unique<flutter_desktop_embedding::TextInputPlugin>(
          state->plugin_handler.get()));

  // Trigger an initial size callback to send size information to Flutter.
  state->monitor_screen_coordinates_per_inch = GetScreenCoordinatesPerInch();
  int width_px, height_px;
  glfwGetFramebufferSize(window, &width_px, &height_px);
  GLFWFramebufferSizeCallback(window, width_px, height_px);

  // Set up GLFW callbacks for the window.
  glfwSetFramebufferSizeCallback(window, GLFWFramebufferSizeCallback);
  GLFWAssignEventCallbacks(window);

  return state;
}

void FlutterEmbedderRunWindowLoop(FlutterWindowRef flutter_window) {
  GLFWwindow *window = flutter_window->window;
#ifdef __linux__
  // Necessary for GTK thread safety.
  XInitThreads();
#endif
  while (!glfwWindowShouldClose(window)) {
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
  FlutterEngineShutdown(flutter_window->engine);
  delete flutter_window;
  glfwDestroyWindow(window);
}

void FlutterEmbedderSendMessage(FlutterWindowRef flutter_window,
                                const char *channel, const uint8_t *message,
                                const size_t message_size) {
  FlutterPlatformMessage platform_message = {
      sizeof(FlutterPlatformMessage),
      channel,
      message,
      message_size,
  };

  FlutterEngineSendPlatformMessage(flutter_window->engine, &platform_message);
}

void FlutterEmbedderSendMessageResponse(
    FlutterWindowRef flutter_window,
    const FlutterEmbedderMessageResponseHandle *handle, const uint8_t *data,
    size_t data_length) {
  FlutterEngineSendPlatformMessageResponse(flutter_window->engine, handle, data,
                                           data_length);
}

void FlutterEmbedderSetMessageCallback(FlutterWindowRef flutter_window,
                                       const char *channel,
                                       FlutterEmbedderMessageCallback callback,
                                       void *user_data) {
  flutter_window->message_dispatcher->SetMessageCallback(channel, callback,
                                                         user_data);
}

void FlutterEmbedderEnableInputBlocking(FlutterWindowRef flutter_window,
                                        const char *channel) {
  flutter_window->message_dispatcher->EnableInputBlockingForChannel(channel);
}

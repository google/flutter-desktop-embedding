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

#ifndef LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_CORE_GLFW_EMBEDDER_H_
#define LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_CORE_GLFW_EMBEDDER_H_

#include <stddef.h>
#include <stdint.h>

#ifdef USE_FDE_TREE_PATHS
#include "../fde_export.h"
#else
#include "fde_export.h"
#endif

#if defined(__cplusplus)
extern "C" {
#endif

// Opaque reference to a Flutter window.
typedef struct FlutterEmbedderState *FlutterWindowRef;

// Opaque handle for tracking responses to messages.
typedef struct _FlutterPlatformMessageResponseHandle
    FlutterEmbedderMessageResponseHandle;

// Sets up the embedder's graphic context. Must be called before any other
// methods.
//
// Note: Internally, this library uses GLFW, which does not support multiple
// copies within the same process. Internally this calls glfwInit, which will
// fail if you have called glfwInit elsewhere in the process.
FDE_EXPORT bool FlutterEmbedderInit();

// Tears down embedder state. Must be called before the process terminates.
FDE_EXPORT void FlutterEmbedderTerminate();

// Creates a Window running a Flutter Application.
//
// FlutterEmbedderInit() must be called prior to this function.
//
// The |assets_path| is the path to the flutter_assets folder for the Flutter
// application to be run. |icu_data_path| is the path to the icudtl.dat file
// for the version of Flutter you are using.
//
// The |arguments| are passed to the Flutter engine. See:
// https://github.com/flutter/engine/blob/master/shell/common/switches.h for
// for details. Not all arguments will apply to embedding mode.
//
// Returns a null pointer in the event of an error. Otherwise, the pointer is
// valid until FlutterEmbedderRunWindowLoop has been called and returned.
// Note that calling FlutterEmbedderCreateWindow without later calling
// FlutterEmbedderRunWindowLoop on the returned reference is a memory leak.
FDE_EXPORT FlutterWindowRef FlutterEmbedderCreateWindow(
    int initial_width, int initial_height, const char *assets_path,
    const char *icu_data_path, const char **arguments, size_t argument_count);

// Loops on Flutter window events until the window is closed.
//
// Once this function returns, FlutterWindowRef is no longer valid, and must
// not be used again.
FDE_EXPORT void FlutterEmbedderRunWindowLoop(FlutterWindowRef flutter_window);

// A received from Flutter.
typedef struct {
  // Size of this struct as created by Flutter.
  size_t struct_size;
  // The name of the channel used for this message.
  const char *channel;
  // The raw message data.
  const uint8_t *message;
  // The length of |message|.
  size_t message_size;
  // The response handle. If non-null, the receiver of this message must call
  // FlutterEmbedderSendMessageResponse exactly once with this handle.
  const FlutterEmbedderMessageResponseHandle *response_handle;
} FlutterEmbedderMessage;

// Function pointer type for message handler callback registration.
//
// The user data will whatever was passed to FlutterEmbedderSetMessageHandler
// for the channel the message is received on.
typedef void (*FlutterEmbedderMessageCallback)(
    FlutterWindowRef flutter_window /*window*/,
    const FlutterEmbedderMessage * /* message*/, void * /* user data */);

// Sends a binary message to the Flutter side on the specified channel.
FDE_EXPORT void FlutterEmbedderSendMessage(FlutterWindowRef flutter_window,
                                           const char *channel,
                                           const uint8_t *message,
                                           const size_t message_size);

// Sends a reply to a FlutterEmbedderMessage for the given response handle.
//
// Once this has been called, |handle| is invalid and must not be used again.
FDE_EXPORT void FlutterEmbedderSendMessageResponse(
    FlutterWindowRef flutter_window,
    const FlutterEmbedderMessageResponseHandle *handle, const uint8_t *data,
    size_t data_length);

// Registers a callback function for incoming binary messages from the Flutter
// side on the specified channel.
//
// Replaces any existing callback. Provide a null handler to unregister the
// existing callback.
//
// If |user_data| is provided, it will be passed in |callback| calls.
FDE_EXPORT void FlutterEmbedderSetMessageCallback(
    FlutterWindowRef flutter_window, const char *channel,
    FlutterEmbedderMessageCallback callback, void *user_data);

// Enables input blocking on the given channel.
//
// If set, then the Flutter window will disable input callbacks
// while waiting for the handler for messages on that channel to run. This is
// useful if handling the message involves showing a modal window, for instance.
//
// This must be called after FlutterEmbedderSetMessageHandler, as setting a
// handler on a channel will reset the input blocking state back to the default
// of disabled.
FDE_EXPORT void FlutterEmbedderEnableInputBlocking(
    FlutterWindowRef flutter_window, const char *channel);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_CORE_GLFW_EMBEDDER_H_

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

#ifndef LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_CORE_EMBEDDER_MESSENGER_H_
#define LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_CORE_EMBEDDER_MESSENGER_H_

#include <stddef.h>
#include <stdint.h>

#include "fde_export.h"

#if defined(__cplusplus)
extern "C" {
#endif

// Opaque reference to a Flutter engine messenger.
typedef struct FlutterEmbedderMessenger *FlutterEmbedderMessengerRef;

// Opaque handle for tracking responses to messages.
typedef struct _FlutterPlatformMessageResponseHandle
    FlutterEmbedderMessageResponseHandle;

// A message received from Flutter.
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
// The user data will be whatever was passed to FlutterEmbedderSetMessageHandler
// for the channel the message is received on.
typedef void (*FlutterEmbedderMessageCallback)(
    FlutterEmbedderMessengerRef /* messenger */,
    const FlutterEmbedderMessage * /* message*/, void * /* user data */);

// Sends a binary message to the Flutter side on the specified channel.
FDE_EXPORT void FlutterEmbedderMessengerSend(
    FlutterEmbedderMessengerRef messenger, const char *channel,
    const uint8_t *message, const size_t message_size);

// Sends a reply to a FlutterEmbedderMessage for the given response handle.
//
// Once this has been called, |handle| is invalid and must not be used again.
FDE_EXPORT void FlutterEmbedderMessengerSendResponse(
    FlutterEmbedderMessengerRef messenger,
    const FlutterEmbedderMessageResponseHandle *handle, const uint8_t *data,
    size_t data_length);

// Registers a callback function for incoming binary messages from the Flutter
// side on the specified channel.
//
// Replaces any existing callback. Provide a null handler to unregister the
// existing callback.
//
// If |user_data| is provided, it will be passed in |callback| calls.
FDE_EXPORT void FlutterEmbedderMessengerSetCallback(
    FlutterEmbedderMessengerRef messenger, const char *channel,
    FlutterEmbedderMessageCallback callback, void *user_data);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_CORE_EMBEDDER_MESSENGER_H_

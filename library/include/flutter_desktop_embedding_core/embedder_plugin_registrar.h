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

#ifndef LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_CORE_EMBEDDER_PLUGIN_REGISTRAR_H_
#define LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_CORE_EMBEDDER_PLUGIN_REGISTRAR_H_

#include <stddef.h>
#include <stdint.h>

#include "embedder_messenger.h"
#include "fde_export.h"

#if defined(__cplusplus)
extern "C" {
#endif

// Opaque reference to a plugin registrar.
typedef struct FlutterEmbedderPluginRegistrar
    *FlutterEmbedderPluginRegistrarRef;

// Returns the engine messenger associated with this registrar.
FDE_EXPORT FlutterEmbedderMessengerRef FlutterEmbedderRegistrarGetMessenger(
    FlutterEmbedderPluginRegistrarRef registrar);

// Enables input blocking on the given channel.
//
// If set, then the Flutter window will disable input callbacks
// while waiting for the handler for messages on that channel to run. This is
// useful if handling the message involves showing a modal window, for instance.
//
// This must be called after FlutterEmbedderSetMessageHandler, as setting a
// handler on a channel will reset the input blocking state back to the
// default of disabled.
FDE_EXPORT void FlutterEmbedderRegistrarEnableInputBlocking(
    FlutterEmbedderPluginRegistrarRef registrar, const char *channel);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_CORE_EMBEDDER_PLUGIN_REGISTRAR_H_

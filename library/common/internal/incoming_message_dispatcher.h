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
#ifndef LIBRARY_COMMON_INTERNAL_INCOMING_MESSAGE_DISPATCHER_H_
#define LIBRARY_COMMON_INTERNAL_INCOMING_MESSAGE_DISPATCHER_H_

#include <functional>
#include <map>
#include <set>
#include <string>
#include <utility>

#include "library/include/flutter_desktop_embedding_core/glfw/embedder.h"

namespace flutter_desktop_embedding {

// Manages per-channel registration of callbacks for handling messages from the
// Flutter engine, and dispatching incoming messages to those handlers.
class IncomingMessageDispatcher {
 public:
  // Creates a new IncomingMessageDispatcher. |window| must remain valid as long
  // as this object exists.
  explicit IncomingMessageDispatcher(FlutterWindowRef window);
  virtual ~IncomingMessageDispatcher();

  // Prevent copying.
  IncomingMessageDispatcher(IncomingMessageDispatcher const &) = delete;
  IncomingMessageDispatcher &operator=(IncomingMessageDispatcher const &) =
      delete;

  // Routes |message| to to the registered handler for its channel, if any.
  //
  // If input blocking has been enabled on that channel, wraps the call to the
  // handler with calls to the given callbacks to block and then unblock input.
  //
  // If no handler is registered for the message's channel, sends a
  // NotImplemented response to the engine.
  void HandleMessage(const FlutterEmbedderMessage &message,
                     std::function<void(void)> input_block_cb = [] {},
                     std::function<void(void)> input_unblock_cb = [] {});

  // Registers a message callback for incoming messages from the Flutter
  // side on the specified channel. |callback| will be called with the message
  // and |user_data| any time a message arrives on that channel.
  //
  // Replaces any existing callback. Pass a null callback to unregister the
  // existing callback.
  void SetMessageCallback(const std::string &channel,
                          FlutterEmbedderMessageCallback callback,
                          void *user_data);

  // Enables input blocking on the given channel name.
  //
  // If set, then the parent window should disable input callbacks
  // while waiting for the handler for messages on that channel to run.
  void EnableInputBlockingForChannel(const std::string &channel);

 private:
  // Handle for interacting with the embedding API.
  // TODO: Provide an interface for the specific functionality needed.
  FlutterWindowRef window_;

  // A map from channel names to the FlutterEmbedderMessageCallback that should
  // be called for incoming messages on that channel, along with the void* user
  // data to pass to it.
  std::map<std::string, std::pair<FlutterEmbedderMessageCallback, void *>>
      callbacks_;

  // Channel names for which input blocking should be enabled during the call to
  // that channel's handler.
  std::set<std::string> input_blocking_channels_;
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_COMMON_INTERNAL_INCOMING_MESSAGE_DISPATCHER_H_

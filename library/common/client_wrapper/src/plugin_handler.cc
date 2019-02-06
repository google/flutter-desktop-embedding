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
#include "plugin_handler.h"

#include "flutter_desktop_embedding/engine_method_result.h"
#include "flutter_desktop_embedding/method_channel.h"

#include <iostream>

namespace flutter_desktop_embedding {

namespace {
// Passes |message| to |user_data|, which must be a BinaryMessageHandler, along
// with a BinaryReply that will send a response on |message|'s response handle.
//
// This serves as an adaptor between the function-pointer-based message callback
// interface provided by embedder.h and the std::function-based message handler
// interface of BinaryMessenger.
void ForwardToHandler(FlutterWindowRef flutter_window,
                      const FlutterEmbedderMessage *message, void *user_data) {
  auto *response_handle = message->response_handle;
  BinaryReply reply_handler = [flutter_window, response_handle](
                                  const uint8_t *reply,
                                  const size_t reply_size) mutable {
    if (!response_handle) {
      std::cerr << "Error: Response can be set only once. Ignoring "
                   "duplicate response."
                << std::endl;
      return;
    }
    FlutterEmbedderSendMessageResponse(flutter_window, response_handle, reply,
                                       reply_size);
    // The engine frees the response handle once
    // FlutterEmbedderSendMessageResponse is called.
    response_handle = nullptr;
  };

  const BinaryMessageHandler &message_handler =
      *static_cast<BinaryMessageHandler *>(user_data);

  message_handler(message->message, message->message_size,
                  std::move(reply_handler));
}
}  // namespace

PluginHandler::PluginHandler(FlutterWindowRef window) : window_(window) {}

PluginHandler::~PluginHandler() {}

// BinaryMessenger:

void PluginHandler::Send(const std::string &channel, const uint8_t *message,
                         const size_t message_size) const {
  FlutterEmbedderSendMessage(window_, channel.c_str(), message, message_size);
}

void PluginHandler::SetMessageHandler(const std::string &channel,
                                      BinaryMessageHandler handler) {
  if (!handler) {
    handlers_.erase(channel);
    FlutterEmbedderSetMessageCallback(window_, channel.c_str(), nullptr,
                                      nullptr);
    return;
  }
  // Save the handler, to keep it alive.
  handlers_[channel] = std::move(handler);
  BinaryMessageHandler *message_handler = &handlers_[channel];
  // Set an adaptor callback that will invoke the handler.
  FlutterEmbedderSetMessageCallback(window_, channel.c_str(), ForwardToHandler,
                                    message_handler);
}

// PluginRegistrar:

void PluginHandler::AddPlugin(std::unique_ptr<Plugin> plugin) {
  plugins_.insert(std::move(plugin));
}

void PluginHandler::EnableInputBlockingForChannel(const std::string &channel) {
  FlutterEmbedderEnableInputBlocking(window_, channel.c_str());
}

}  // namespace flutter_desktop_embedding

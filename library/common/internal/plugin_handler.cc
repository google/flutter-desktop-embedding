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
#include "library/common/internal/plugin_handler.h"

#include "library/include/flutter_desktop_embedding/engine_method_result.h"
#include "library/include/flutter_desktop_embedding/method_channel.h"

#include <iostream>

namespace flutter_desktop_embedding {

PluginHandler::PluginHandler(FlutterEngine engine) : engine_(engine) {}

PluginHandler::~PluginHandler() {}

void PluginHandler::HandleMethodCallMessage(
    const FlutterPlatformMessage *message,
    std::function<void(void)> input_block_cb,
    std::function<void(void)> input_unblock_cb) {
  std::string channel(message->channel);
  auto *response_handle = message->response_handle;
  auto *response_engine = engine_;
  BinaryReply reply_handler = [response_engine, response_handle](
                                  const uint8_t *reply,
                                  const size_t reply_size) mutable {
    if (!response_handle) {
      std::cerr << "Error: Response can be set only once. Ignoring "
                   "duplicate response."
                << std::endl;
      return;
    }
    FlutterEngineSendPlatformMessageResponse(response_engine, response_handle,
                                             reply, reply_size);
    // The engine frees the response handle once
    // FlutterEngineSendPlatformMessageResponse is called.
    response_handle = nullptr;
  };

  // Find the handler for the channel; if there isn't one, report the failure.
  if (handlers_.find(channel) == handlers_.end()) {
    reply_handler(nullptr, 0);
    return;
  }
  const BinaryMessageHandler &message_handler = handlers_[channel];

  // Process the call, handling input blocking if requested.
  bool block_input = input_blocking_channels_.count(channel) > 0;
  if (block_input) {
    input_block_cb();
  }
  message_handler(message->message, message->message_size,
                  std::move(reply_handler));
  if (block_input) {
    input_unblock_cb();
  }
}

// BinaryMessenger:

void PluginHandler::Send(const std::string &channel, const uint8_t *message,
                         const size_t message_size) const {
  FlutterPlatformMessage platform_message = {
      sizeof(FlutterPlatformMessage),
      channel.c_str(),
      message,
      message_size,
  };
  FlutterEngineSendPlatformMessage(engine_, &platform_message);
}

void PluginHandler::SetMessageHandler(const std::string &channel,
                                      BinaryMessageHandler handler) {
  handlers_[channel] = std::move(handler);
}

// PluginRegistrar:

void PluginHandler::AddPlugin(std::unique_ptr<Plugin> plugin) {
  plugins_.insert(std::move(plugin));
}

void PluginHandler::EnableInputBlockingForChannel(const std::string &channel) {
  input_blocking_channels_.insert(channel);
}

}  // namespace flutter_desktop_embedding

// Copyright 2019 Google LLC
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
#include "library/common/internal/incoming_message_dispatcher.h"

namespace flutter_desktop_embedding {

IncomingMessageDispatcher::IncomingMessageDispatcher(FlutterWindowRef window)
    : window_(window) {}

IncomingMessageDispatcher::~IncomingMessageDispatcher() {}

void IncomingMessageDispatcher::HandleMessage(
    const FlutterEmbedderMessage &message,
    std::function<void(void)> input_block_cb,
    std::function<void(void)> input_unblock_cb) {
  std::string channel(message.channel);

  // Find the handler for the channel; if there isn't one, report the failure.
  if (callbacks_.find(channel) == callbacks_.end()) {
    FlutterEmbedderSendMessageResponse(window_, message.response_handle,
                                       nullptr, 0);
    return;
  }
  auto &callback_info = callbacks_[channel];
  FlutterEmbedderMessageCallback message_callback = callback_info.first;

  // Process the call, handling input blocking if requested.
  bool block_input = input_blocking_channels_.count(channel) > 0;
  if (block_input) {
    input_block_cb();
  }
  message_callback(window_, &message, callback_info.second);
  if (block_input) {
    input_unblock_cb();
  }
}

void IncomingMessageDispatcher::SetMessageCallback(
    const std::string &channel, FlutterEmbedderMessageCallback callback,
    void *user_data) {
  if (!callback) {
    callbacks_.erase(channel);
    return;
  }
  callbacks_[channel] = std::make_pair(callback, user_data);
}

void IncomingMessageDispatcher::EnableInputBlockingForChannel(
    const std::string &channel) {
  input_blocking_channels_.insert(channel);
}

}  // namespace flutter_desktop_embedding

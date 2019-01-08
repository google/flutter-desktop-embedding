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
#ifndef LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_BASIC_MESSAGE_CHANNEL_H_
#define LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_BASIC_MESSAGE_CHANNEL_H_

#include <iostream>
#include <string>

#include "binary_messenger.h"
#include "fde_export.h"
#include "message_codec.h"

namespace flutter_desktop_embedding {

// A message reply callback.
//
// Used for submitting a reply back to a Flutter message sender.
template <typename T>
using MessageReply = std::function<void(const T &reply)>;

// A handler for receiving a message from the Flutter engine.
//
// Implementations must asynchronously call reply exactly once with the reply
// to the message.
template <typename T>
using MessageHandler =
    std::function<void(const T &message, MessageReply<T> reply)>;

// A channel for communicating with the Flutter engine by sending asynchronous
// messages.
template <typename T>
class FDE_EXPORT BasicMessageChannel {
 public:
  // Creates an instance that sends and receives method calls on the channel
  // named |name|, encoded with |codec| and dispatched via |messenger|.
  //
  // TODO: Make codec optional once the standard codec is supported (Issue #67).
  BasicMessageChannel(BinaryMessenger *messenger, const std::string &name,
                      const MessageCodec<T> *codec)
      : messenger_(messenger), name_(name), codec_(codec) {}
  ~BasicMessageChannel() {}

  // Prevent copying.
  BasicMessageChannel(BasicMessageChannel const &) = delete;
  BasicMessageChannel &operator=(BasicMessageChannel const &) = delete;

  // Sends a message to the Flutter engine on this channel.
  void Send(const T &message) {
    std::unique_ptr<std::vector<uint8_t>> raw_message =
        codec_->EncodeMessage(message);
    messenger_->Send(name_, raw_message->data(), raw_message->size());
  }

  // TODO: Add support for a version of Send expecting a reply once
  // https://github.com/flutter/flutter/issues/18852 is fixed.

  // Registers a handler that should be called any time a message is
  // received on this channel.
  void SetMessageHandler(MessageHandler<T> handler) const {
    const auto *codec = codec_;
    std::string channel_name = name_;
    BinaryMessageHandler binary_handler = [handler, codec, channel_name](
                                              const uint8_t *binary_message,
                                              const size_t binary_message_size,
                                              BinaryReply binary_reply) {
      // Use this channel's codec to decode the message and build a reply
      // handler.
      std::unique_ptr<T> message =
          codec->DecodeMessage(binary_message, binary_message_size);
      if (!message) {
        std::cerr << "Unable to decode message on channel " << channel_name
                  << std::endl;
        binary_reply(nullptr, 0);
        return;
      }

      MessageReply<T> unencoded_reply = [binary_reply,
                                         codec](const T &unencoded_response) {
        auto binary_response = codec->EncodeMessage(unencoded_response);
        binary_reply(binary_response->data(), binary_response->size());
      };
      handler(*message, std::move(unencoded_reply));
    };
    messenger_->SetMessageHandler(name_, std::move(binary_handler));
  }

 private:
  BinaryMessenger *messenger_;
  std::string name_;
  const MessageCodec<T> *codec_;
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_BASIC_MESSAGE_CHANNEL_H_

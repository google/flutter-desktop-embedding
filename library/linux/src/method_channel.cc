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
#include "library/linux/include/flutter_desktop_embedding/method_channel.h"

#include <iostream>

#include "library/linux/src/internal/engine_method_result.h"

namespace flutter_desktop_embedding {

MethodChannel::MethodChannel(BinaryMessenger *messenger,
                             const std::string &name, const MethodCodec *codec)
    : messenger_(messenger), name_(name), codec_(codec) {}

MethodChannel::~MethodChannel() {}

void MethodChannel::InvokeMethodCall(const MethodCall &method_call) const {
  std::unique_ptr<std::vector<uint8_t>> message =
      codec_->EncodeMethodCall(method_call);
  messenger_->Send(name_, message->data(), message->size());
}

void MethodChannel::SetMethodCallHandler(MethodCallHandler handler) const {
  const auto *codec = codec_;
  std::string channel_name = name_;
  BinaryMessageHandler binary_handler = [handler, codec, channel_name](
                                            const uint8_t *message,
                                            const size_t message_size,
                                            BinaryReply reply) {
    // Use this channel's codec to decode the call and build a result handler.
    auto result = std::make_unique<EngineMethodResult>(std::move(reply), codec);
    std::unique_ptr<MethodCall> method_call =
        codec->DecodeMethodCall(message, message_size);
    if (!method_call) {
      std::cerr << "Unable to construct method call from message on channel "
                << channel_name << std::endl;
      result->NotImplemented();
      return;
    }
    handler(*method_call, std::move(result));
  };
  messenger_->SetMessageHandler(name_, std::move(binary_handler));
}

}  // namespace flutter_desktop_embedding

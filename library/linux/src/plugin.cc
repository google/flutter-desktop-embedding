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
#include "library/linux/include/flutter_desktop_embedding/plugin.h"

#include "library/linux/include/flutter_desktop_embedding/json_method_codec.h"

namespace flutter_desktop_embedding {

Plugin::Plugin(const std::string &channel, bool input_blocking)
    : channel_(channel), messenger_(nullptr), input_blocking_(input_blocking) {}

Plugin::~Plugin() {}

void Plugin::SetBinaryMessenger(BinaryMessenger *messenger) {
  messenger_ = messenger;
  RegisterMethodChannels(messenger);
}

void Plugin::InvokeMethodCall(const MethodCall &method_call) {
  if (!messenger_) {
    return;
  }
  std::unique_ptr<std::vector<uint8_t>> message =
      GetCodec().EncodeMethodCall(method_call);
  messenger_->Send(channel_, message->data(), message->size());
}

}  // namespace flutter_desktop_embedding

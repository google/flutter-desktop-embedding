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
#include "library/linux/src/internal/plugin_handler.h"

#include "library/linux/src/internal/engine_method_result.h"

#include <iostream>

namespace flutter_desktop_embedding {

PluginHandler::PluginHandler(FlutterEngine engine) : engine_(engine) {}

PluginHandler::~PluginHandler() {}

bool PluginHandler::AddPlugin(std::unique_ptr<Plugin> plugin) {
  if (plugins_.find(plugin->channel()) != plugins_.end()) {
    return false;
  }
  plugins_.insert(std::make_pair(plugin->channel(), std::move(plugin)));
  return true;
}

void PluginHandler::HandleMethodCallMessage(
    const FlutterPlatformMessage *message,
    std::function<void(void)> input_block_cb,
    std::function<void(void)> input_unblock_cb) {
  std::string channel(message->channel);

  // Find the plugin for the channel; if there isn't one, report the failure.
  if (plugins_.find(channel) == plugins_.end()) {
    auto result =
        std::make_unique<flutter_desktop_embedding::EngineMethodResult>(
            engine_, message->response_handle, nullptr);
    result->NotImplemented();
    return;
  }
  const std::unique_ptr<Plugin> &plugin = plugins_[channel];

  // Use the plugin's codec to decode the call and build a result handler.
  const flutter_desktop_embedding::MethodCodec &codec = plugin->GetCodec();
  auto result = std::make_unique<flutter_desktop_embedding::EngineMethodResult>(
      engine_, message->response_handle, &codec);
  std::unique_ptr<flutter_desktop_embedding::MethodCall> method_call =
      codec.DecodeMethodCall(message->message, message->message_size);
  if (!method_call) {
    std::cerr << "Unable to construct method call from message on channel "
              << message->channel << std::endl;
    result->NotImplemented();
    return;
  }

  // Process the call, handling input blocking if requested by the plugin.
  if (plugin->input_blocking()) {
    input_block_cb();
  }
  plugin->HandleMethodCall(*method_call, std::move(result));
  if (plugin->input_blocking()) {
    input_unblock_cb();
  }
}

void PluginHandler::Send(const std::string &channel, const uint8_t *message,
                         const size_t message_size) const {
  FlutterPlatformMessage platform_message = {
      .struct_size = sizeof(FlutterPlatformMessage),
      .channel = channel.c_str(),
      .message = message,
      .message_size = message_size,
  };
  FlutterEngineSendPlatformMessage(engine_, &platform_message);
}

}  // namespace flutter_desktop_embedding

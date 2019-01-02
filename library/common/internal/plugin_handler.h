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
#ifndef LIBRARY_COMMON_INTERNAL_PLUGIN_HANDLER_H_
#define LIBRARY_COMMON_INTERNAL_PLUGIN_HANDLER_H_

#include <map>
#include <memory>
#include <set>
#include <string>

#include <flutter_embedder.h>

#include "library/include/flutter_desktop_embedding/binary_messenger.h"
#include "library/include/flutter_desktop_embedding/plugin_registrar.h"

namespace flutter_desktop_embedding {

// A class for managing a set of plugins.
//
// The plugins all map from a unique channel name to an actual plugin.
class PluginHandler : public BinaryMessenger, public PluginRegistrar {
 public:
  // Creates a new PluginHandler. |engine| must remain valid as long as this
  // object exists.
  explicit PluginHandler(FlutterEngine engine);
  virtual ~PluginHandler();

  // Prevent copying.
  PluginHandler(PluginHandler const &) = delete;
  PluginHandler &operator=(PluginHandler const &) = delete;

  // Decodes the method call in |message| and routes it to to the registered
  // handler for |message|'s channel, if any.
  //
  // If input blocking has been enabled on that channel, wraps the call to the
  // handler with calls to the given callbacks to block and then unblock input.
  //
  // If no handler is registered for the message's channel, sends a
  // NotImplemented response to the engine.
  void HandleMethodCallMessage(
      const FlutterPlatformMessage *message,
      std::function<void(void)> input_block_cb = [] {},
      std::function<void(void)> input_unblock_cb = [] {});

  // BinaryMessenger implementation:
  void Send(const std::string &channel, const uint8_t *message,
            const size_t message_size) const override;
  void SetMessageHandler(const std::string &channel,
                         BinaryMessageHandler handler) override;

  // PluginRegistrar implementation:
  BinaryMessenger *messenger() override { return this; }
  void AddPlugin(std::unique_ptr<Plugin> plugin) override;
  void EnableInputBlockingForChannel(const std::string &channel) override;

 private:
  FlutterEngine engine_;

  // Plugins registered for ownership via PluginRegistrar.
  std::set<std::unique_ptr<Plugin>> plugins_;

  // A map from channel names to the BinaryMessageHandler that should be called
  // for incoming messages on that channel.
  std::map<std::string, BinaryMessageHandler> handlers_;

  // Channel names for which input blocking should be enabled during the call to
  // that channel's handler.
  std::set<std::string> input_blocking_channels_;
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_COMMON_INTERNAL_PLUGIN_HANDLER_H_

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

// TODO: Change USE_FDE_TREE_PATHS branches to use project-relative paths
// once Windows clients aren't relying on it.
#ifdef USE_FDE_TREE_PATHS
#include <flutter_desktop_embedding_core/glfw/embedder.h>
#else
#include <flutter_desktop_embedding_core/embedder.h>
#endif

#include "flutter_desktop_embedding/binary_messenger.h"
#include "flutter_desktop_embedding/plugin_registrar.h"

namespace flutter_desktop_embedding {

// Manages plugin registration, as well as messaging to and from the Flutter
// engine.
class PluginHandler : public BinaryMessenger, public PluginRegistrar {
 public:
  // Creates a new PluginHandler. |window| and |message_dispatcher| must remain
  // valid as long as this object exists.
  explicit PluginHandler(FlutterWindowRef window);
  virtual ~PluginHandler();

  // Prevent copying.
  PluginHandler(PluginHandler const &) = delete;
  PluginHandler &operator=(PluginHandler const &) = delete;

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
  // Handle for interacting with the embedding API.
  // TODO: Provide an interface for the specific functionality needed.
  FlutterWindowRef window_;

  // Plugins registered for ownership via PluginRegistrar.
  std::set<std::unique_ptr<Plugin>> plugins_;

  // A map from channel names to the BinaryMessageHandler that should be called
  // for incoming messages on that channel.
  std::map<std::string, BinaryMessageHandler> handlers_;
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_COMMON_INTERNAL_PLUGIN_HANDLER_H_

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
#ifndef LINUX_LIBRARY_SRC_INTERNAL_PLUGIN_HANDLER_H_
#define LINUX_LIBRARY_SRC_INTERNAL_PLUGIN_HANDLER_H_

#include <map>
#include <memory>
#include <string>

#include <flutter_embedder.h>

#include "linux/library/include/flutter_desktop_embedding/plugin.h"

namespace flutter_desktop_embedding {

// A class for managing a set of plugins.
//
// The plugins all map from a unique channel name to an actual plugin.
class PluginHandler {
 public:
  // Creates a new PluginHandler. |engine| must remain valid as long as this
  // object exists.
  explicit PluginHandler(FlutterEngine engine);
  virtual ~PluginHandler();

  // Prevent copying.
  PluginHandler(PluginHandler const &) = delete;
  PluginHandler &operator=(PluginHandler const &) = delete;

  // Attempts to add the given plugin.
  //
  // Returns true if the plugin could be registered, false if there is already
  // a plugin registered under the same channel.
  bool AddPlugin(std::unique_ptr<Plugin> plugin);

  // Decodes the method call in |message| and routes it to to the plugin
  // registered for |message|'s channel, if any.
  //
  // In the event that the plugin on the message's channel is input blocking,
  // calls the caller-defined callbacks to block and then unblock input.
  //
  // If no plugin is registered for the message's channel, sends a
  // NotImplemented response to the engine.
  //
  // TODO: Move to an API matching Flutter's MethodChannel.
  void HandleMethodCallMessage(const FlutterPlatformMessage *message,
                               std::function<void(void)> input_block_cb = [] {},
                               std::function<void(void)> input_unblock_cb =
                                   [] {});

 private:
  FlutterEngine engine_;
  std::map<std::string, std::unique_ptr<Plugin>> plugins_;
};

}  // namespace flutter_desktop_embedding

#endif  // LINUX_LIBRARY_SRC_INTERNAL_PLUGIN_HANDLER_H_

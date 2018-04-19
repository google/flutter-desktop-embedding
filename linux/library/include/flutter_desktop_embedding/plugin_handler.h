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
#ifndef LINUX_INCLUDE_PLUGIN_HANDLER_H_
#define LINUX_INCLUDE_PLUGIN_HANDLER_H_
#include <json/json.h>

#include <functional>
#include <map>
#include <memory>
#include <string>

#include "plugin.h"

namespace flutter_desktop_embedding {

typedef std::function<void(GLFWwindow*, int, int, int, int)>
    KeyboardHookFunction;

typedef std::function<void(GLFWwindow*, unsigned int)> CharHookFunction;

// A class for managing a set of plugins.
//
// The plugins all map from a unique channel name to an actual plugin.
class PluginHandler {
 public:
  PluginHandler();
  virtual ~PluginHandler();

  // Attempts to add the given plugin.
  //
  // Returns true if the plugin could be registered, false if there is already
  // a plugin registered under the same channel.
  bool AddPlugin(std::unique_ptr<Plugin> plugin);

  // Sends a JSON message for the plugin on |channel|.
  //
  // In the event that the plugin on |channel| is input blocking, calls the
  // caller-defined callbacks to block and then unblock input.
  //
  // See the documentation for Plugin on the type of response that can be
  // returned.
  //
  // If there is no plugin under |channel| Json::nullValue is returned.
  Json::Value HandlePlatformMessage(
      const std::string& channel, const Json::Value& message,
      std::function<void(void)> input_block_cb = [] {},
      std::function<void(void)> input_unblock_cb = [] {});

  const std::vector<KeyboardHookFunction>& keyboard_hooks() const {
    return keyboard_hooks_;
  }

  const std::vector<CharHookFunction>& char_hooks() const {
    return char_hooks_;
  }

 private:
  std::map<std::string, std::unique_ptr<Plugin>> plugins_;
  std::vector<KeyboardHookFunction> keyboard_hooks_;
  std::vector<CharHookFunction> char_hooks_;
};

}  // namespace flutter_desktop_embedding

#endif  // LINUX_INCLUDE_PLUGIN_HANDLER_H_

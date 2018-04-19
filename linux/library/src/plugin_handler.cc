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
#include <flutter_desktop_embedding/plugin_handler.h>

#include <iostream>

namespace flutter_desktop_embedding {

PluginHandler::PluginHandler() {}

PluginHandler::~PluginHandler() {}

bool PluginHandler::AddPlugin(std::unique_ptr<Plugin> plugin) {
  if (plugins_.find(plugin->channel()) != plugins_.end()) {
    return false;
  }
  Plugin *plugin_raw_ptr = plugin.get();
  // TODO(awdavies): This function might be a noop. Might be better to not add
  // it if that's the case (somehow).
  keyboard_hooks_.push_back([plugin_raw_ptr](GLFWwindow *window, int key,
                                             int scancode, int action,
                                             int mods) {
    plugin_raw_ptr->KeyboardHook(window, key, scancode, action, mods);
  });
  char_hooks_.push_back(
      [plugin_raw_ptr](GLFWwindow *window, unsigned int code_point) {
        plugin_raw_ptr->CharHook(window, code_point);
      });
  plugins_.insert(std::make_pair(plugin->channel(), std::move(plugin)));
  return true;
}

Json::Value PluginHandler::HandlePlatformMessage(
    const std::string &channel, const Json::Value &message,
    std::function<void(void)> input_block_cb,
    std::function<void(void)> input_unblock_cb) {
  if (plugins_.find(channel) != plugins_.end()) {
    const std::unique_ptr<Plugin> &plugin = plugins_[channel];
    if (plugin->input_blocking()) {
      input_block_cb();
    }
    Json::Value response = plugin->HandlePlatformMessage(message);
    if (plugin->input_blocking()) {
      input_unblock_cb();
    }
    return response;
  }
  return Json::nullValue;
}

}  // namespace flutter_desktop_embedding

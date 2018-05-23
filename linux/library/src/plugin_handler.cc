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
  plugins_.insert(std::make_pair(plugin->channel(), std::move(plugin)));
  return true;
}

void PluginHandler::HandleMethodCall(
    const std::string &channel, const MethodCall &method_call,
    std::unique_ptr<MethodResult> result,
    std::function<void(void)> input_block_cb,
    std::function<void(void)> input_unblock_cb) {
  if (plugins_.find(channel) != plugins_.end()) {
    const std::unique_ptr<Plugin> &plugin = plugins_[channel];
    if (plugin->input_blocking()) {
      input_block_cb();
    }
    plugin->HandleMethodCall(method_call, std::move(result));
    if (plugin->input_blocking()) {
      input_unblock_cb();
    }
  } else {
    result->NotImplemented();
  }
}

}  // namespace flutter_desktop_embedding

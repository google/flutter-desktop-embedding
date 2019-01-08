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
#ifndef PLUGINS_FILE_CHOOSER_LINUX_INCLUDE_FILE_CHOOSER_FILE_CHOOSER_PLUGIN_H_
#define PLUGINS_FILE_CHOOSER_LINUX_INCLUDE_FILE_CHOOSER_FILE_CHOOSER_PLUGIN_H_

#include <memory>

#include <json/json.h>

#include <flutter_desktop_embedding/method_channel.h>
#include <flutter_desktop_embedding/plugin_registrar.h>

#ifdef FILE_CHOOSER_PLUGIN_IMPL
#define FILE_CHOOSER_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FILE_CHOOSER_PLUGIN_EXPORT
#endif

namespace plugins_file_chooser {

// Implements a file chooser plugin.
class FILE_CHOOSER_PLUGIN_EXPORT FileChooserPlugin
    : public flutter_desktop_embedding::Plugin {
 public:
  static void RegisterWithRegistrar(
      flutter_desktop_embedding::PluginRegistrar *registrar);

  virtual ~FileChooserPlugin();

 private:
  // Creates a plugin that communicates on the given channel.
  FileChooserPlugin(
      std::unique_ptr<flutter_desktop_embedding::MethodChannel<Json::Value>>
          channel);

  // Called when a method is called on |channel_|;
  void HandleMethodCall(
      const flutter_desktop_embedding::MethodCall<Json::Value> &method_call,
      std::unique_ptr<flutter_desktop_embedding::MethodResult<Json::Value>>
          result);

  // The MethodChannel used for communication with the Flutter engine.
  std::unique_ptr<flutter_desktop_embedding::MethodChannel<Json::Value>>
      channel_;
};

}  // namespace plugins_file_chooser

#endif  // PLUGINS_FILE_CHOOSER_LINUX_INCLUDE_FILE_CHOOSER_FILE_CHOOSER_PLUGIN_H_

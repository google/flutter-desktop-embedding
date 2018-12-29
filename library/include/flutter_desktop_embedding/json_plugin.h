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
#ifndef LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_JSON_PLUGIN_H_
#define LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_JSON_PLUGIN_H_

#include <memory>
#include <string>

#include "json_method_call.h"
#include "method_channel.h"
#include "plugin.h"

namespace flutter_desktop_embedding {

// A base class for plugins using the JSON method codec.
//
// Provides a few utility shims from the type-agnostic Plugin class.
class JsonPlugin : public Plugin {
 public:
  // See Plugin for constructor details.
  explicit JsonPlugin(const std::string &channel, bool input_blocking = false);
  virtual ~JsonPlugin();

  // Prevent copying.
  JsonPlugin(JsonPlugin const &) = delete;
  JsonPlugin &operator=(JsonPlugin const &) = delete;

  // Plugin implementation:
  const MethodCodec &GetCodec() const override;
  void HandleMethodCall(const MethodCall &method_call,
                        std::unique_ptr<MethodResult> result) override;

 protected:
  // Plugin implementation:
  void RegisterMethodChannels(BinaryMessenger *messenger) override;

  // Identical to HandleMethodCall, except that the call has been cast to the
  // more specific type. Subclasses must implement this instead of
  // HandleMethodCall.
  virtual void HandleJsonMethodCall(const JsonMethodCall &method_call,
                                    std::unique_ptr<MethodResult> result) = 0;

  // Calls InvokeMethodCall on |method_channel_| with a JsonMethodCall
  // constructed from the given values.
  void InvokeMethod(const std::string &method,
                    const Json::Value &arguments = Json::Value());

 private:
  // The MethodChannel used by this plugin for communication with the Flutter
  // engine.
  std::unique_ptr<MethodChannel> method_channel_;
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_JSON_PLUGIN_H_

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
#include "library/shared/include/flutter_desktop_embedding/json_plugin.h"

#include "library/shared/include/flutter_desktop_embedding/json_method_codec.h"

namespace flutter_desktop_embedding {

JsonPlugin::JsonPlugin(const std::string &channel, bool input_blocking)
    : Plugin(channel, input_blocking) {}

JsonPlugin::~JsonPlugin() {}

const MethodCodec &JsonPlugin::GetCodec() const {
  return JsonMethodCodec::GetInstance();
}

void JsonPlugin::HandleMethodCall(const MethodCall &method_call,
                                  std::unique_ptr<MethodResult> result) {
  HandleJsonMethodCall(dynamic_cast<const JsonMethodCall &>(method_call),
                       std::move(result));
}

void JsonPlugin::RegisterMethodChannels(BinaryMessenger *messenger) {
  method_channel_ =
      std::make_unique<MethodChannel>(messenger, channel(), &GetCodec());

  MethodCallHandler handler = [this](const MethodCall &call,
                                     std::unique_ptr<MethodResult> result) {
    HandleMethodCall(call, std::move(result));
  };
  method_channel_->SetMethodCallHandler(std::move(handler));
}

void JsonPlugin::InvokeMethod(const std::string &method,
                              const Json::Value &arguments) {
  method_channel_->InvokeMethodCall(JsonMethodCall(method, arguments));
}

}  // namespace flutter_desktop_embedding

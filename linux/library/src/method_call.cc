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
#include "linux/library/include/flutter_desktop_embedding/method_call.h"

namespace flutter_desktop_embedding {

constexpr char kMessageMethodKey[] = "method";
constexpr char kMessageArgumentsKey[] = "args";

MethodCall::MethodCall(const std::string &method_name,
                       const Json::Value &arguments)
    : method_name_(method_name), arguments_(arguments) {}

MethodCall::~MethodCall() {}

std::unique_ptr<MethodCall> MethodCall::CreateFromMessage(
    const Json::Value &message) {
  Json::Value method = message[kMessageMethodKey];
  if (method.isNull()) {
    return nullptr;
  }
  Json::Value arguments = message[kMessageArgumentsKey];
  return std::make_unique<MethodCall>(method.asString(), arguments);
}

Json::Value MethodCall::AsMessage() const {
  Json::Value message(Json::objectValue);
  message[kMessageMethodKey] = method_name_;
  message[kMessageArgumentsKey] = arguments_;
  return message;
}

}  // namespace flutter_desktop_embedding

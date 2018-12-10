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
#include "library/common/include/flutter_desktop_embedding/json_method_call.h"

namespace flutter_desktop_embedding {

JsonMethodCall::JsonMethodCall(const std::string &method_name,
                               const Json::Value &arguments)
    : MethodCall(method_name), arguments_(arguments) {}

JsonMethodCall::~JsonMethodCall() {}

const void *JsonMethodCall::arguments() const { return &arguments_; }

const Json::Value &JsonMethodCall::GetArgumentsAsJson() const {
  return arguments_;
}

}  // namespace flutter_desktop_embedding

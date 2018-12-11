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
#ifndef LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_JSON_METHOD_CALL_H_
#define LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_JSON_METHOD_CALL_H_

#include <string>

#include <json/json.h>

#include "method_call.h"

namespace flutter_desktop_embedding {

// A concrete implmentation of MethodCall for use with the JSON codec.
class JsonMethodCall : public MethodCall {
 public:
  // Creates a MethodCall with the given name and, optionally, arguments.
  explicit JsonMethodCall(const std::string &method_name,
                          const Json::Value &arguments = Json::Value());
  ~JsonMethodCall();

  // Prevent copying.
  JsonMethodCall(JsonMethodCall const &) = delete;
  JsonMethodCall &operator=(JsonMethodCall const &) = delete;

  // MethodCall:
  // Returns a pointer to a Json::Value object. This will never return null;
  // 'no arguments' is represented with a JSON::nullValue.
  const void *arguments() const override;

  // Returns a reference to the object pointed to by arguments().
  // This is a convience method for code that is interacting directly with a
  // JsonMethodCall to avoid casting and dereferencing.
  const Json::Value &GetArgumentsAsJson() const;

 private:
  Json::Value arguments_;
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_JSON_METHOD_CALL_H_

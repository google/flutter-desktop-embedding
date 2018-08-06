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
#ifndef LINUX_LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_METHOD_CALL_H_
#define LINUX_LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_METHOD_CALL_H_

#include <json/json.h>

#include <memory>
#include <string>

#include <flutter_embedder.h>

namespace flutter_desktop_embedding {

// An object encapsulating a method call from Flutter.
// TODO: Move serialization details into a method codec class, to match mobile
// Flutter plugin APIs.
class MethodCall {
 public:
  // Creates a MethodCall with the given name and, optionally, arguments.
  explicit MethodCall(const std::string &method_name,
                      const Json::Value &arguments = Json::Value());

  // Returns a new MethodCall created from a JSON message received from the
  // Flutter engine.
  static std::unique_ptr<MethodCall> CreateFromMessage(
      const Json::Value &message);
  ~MethodCall();

  // The name of the method being called.
  const std::string &method_name() const { return method_name_; }

  // The arguments to the method call, or a nullValue if there are none.
  const Json::Value &arguments() const { return arguments_; }

  // Returns a version of the method call serialized in the format expected by
  // the Flutter engine.
  Json::Value AsMessage() const;

 private:
  std::string method_name_;
  Json::Value arguments_;
};

}  // namespace flutter_desktop_embedding

#endif  // LINUX_LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_METHOD_CALL_H_

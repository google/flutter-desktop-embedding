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
#ifndef LIBRARY_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_TYPED_METHOD_CALL_H_
#define LIBRARY_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_TYPED_METHOD_CALL_H_

#include <memory>
#include <string>

namespace flutter_desktop_embedding {

// An object encapsulating a method call from Flutter whose arguments are of
// type T.
template <typename T>
class MethodCall {
 public:
  // Creates a MethodCall with the given name and arguments.
  explicit MethodCall(const std::string &method_name,
                      std::unique_ptr<T> arguments)
      : method_name_(method_name), arguments_(std::move(arguments)) {}
  virtual ~MethodCall() = default;

  // Prevent copying.
  MethodCall(MethodCall<T> const &) = delete;
  MethodCall &operator=(MethodCall<T> const &) = delete;

  // The name of the method being called.
  const std::string &method_name() const { return method_name_; }

  // The arguments to the method call, or NULL if there are none.
  const T *arguments() const { return arguments_.get(); }

 private:
  std::string method_name_;
  std::unique_ptr<T> arguments_;
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_TYPED_METHOD_CALL_H_

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
#ifndef LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_METHOD_CALL_H_
#define LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_METHOD_CALL_H_

#include <string>

namespace flutter_desktop_embedding {

// An object encapsulating a method call from Flutter.
class MethodCall {
 public:
  // Creates a MethodCall with the given name. Used only as a superclass
  // constructor for subclasses, which should also take the arguments.
  explicit MethodCall(const std::string &method_name);
  virtual ~MethodCall();

  // Prevent copying.
  MethodCall(MethodCall const &) = delete;
  MethodCall &operator=(MethodCall const &) = delete;

  // The name of the method being called.
  const std::string &method_name() const { return method_name_; }

  // The arguments to the method call, or NULL if there are none. The type of
  // the object being pointed to is determined by the concrete subclasses.
  virtual const void *arguments() const = 0;

 private:
  std::string method_name_;
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_METHOD_CALL_H_

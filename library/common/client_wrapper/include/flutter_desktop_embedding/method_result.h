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
#ifndef LIBRARY_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_METHOD_RESULT_H_
#define LIBRARY_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_METHOD_RESULT_H_

#include <string>

namespace flutter_desktop_embedding {

// Encapsulates a result sent back to the Flutter engine in response to a
// MethodCall. Only one method should be called on any given instance.
template <typename T>
class MethodResult {
 public:
  MethodResult() = default;
  virtual ~MethodResult() = default;

  // Prevent copying.
  MethodResult(MethodResult const &) = delete;
  MethodResult &operator=(MethodResult const &) = delete;

  // Sends a success response, indicating that the call completed successfully.
  // An optional value can be provided as part of the success message.
  void Success(const T *result = nullptr) { SuccessInternal(result); }

  // Sends an error response, indicating that the call was understood but
  // handling failed in some way. A string error code must be provided, and in
  // addition an optional user-readable error_message and/or details object can
  // be included.
  void Error(const std::string &error_code,
             const std::string &error_message = "",
             const T *error_details = nullptr) {
    ErrorInternal(error_code, error_message, error_details);
  }

  // Sends a not-implemented response, indicating that the method either was not
  // recognized, or has not been implemented.
  void NotImplemented() { NotImplementedInternal(); }

 protected:
  // Internal implementation of the interface methods above, to be implemented
  // in subclasses.
  virtual void SuccessInternal(const T *result) = 0;
  virtual void ErrorInternal(const std::string &error_code,
                             const std::string &error_message,
                             const T *error_details) = 0;
  virtual void NotImplementedInternal() = 0;
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_METHOD_RESULT_H_

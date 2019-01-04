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
#include "library/include/flutter_desktop_embedding/method_result.h"

namespace flutter_desktop_embedding {

MethodResult::MethodResult() {}

MethodResult::~MethodResult() {}

void MethodResult::Success(const void *result) { SuccessInternal(result); }

void MethodResult::Error(const std::string &error_code,
                         const std::string &error_message,
                         const void *error_details) {
  ErrorInternal(error_code, error_message, error_details);
}

void MethodResult::NotImplemented() { NotImplementedInternal(); }

}  // namespace flutter_desktop_embedding

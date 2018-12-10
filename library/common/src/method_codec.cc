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
#include "library/common/include/flutter_desktop_embedding/method_codec.h"

namespace flutter_desktop_embedding {

MethodCodec::~MethodCodec() {}

std::unique_ptr<MethodCall> MethodCodec::DecodeMethodCall(
    const uint8_t *message, const size_t message_size) const {
  return DecodeMethodCallInternal(message, message_size);
}

std::unique_ptr<std::vector<uint8_t>> MethodCodec::EncodeMethodCall(
    const MethodCall &method_call) const {
  return EncodeMethodCallInternal(method_call);
}

std::unique_ptr<std::vector<uint8_t>> MethodCodec::EncodeSuccessEnvelope(
    const void *result) const {
  return EncodeSuccessEnvelopeInternal(result);
}

std::unique_ptr<std::vector<uint8_t>> MethodCodec::EncodeErrorEnvelope(
    const std::string &error_code, const std::string &error_message,
    const void *error_details) const {
  return EncodeErrorEnvelopeInternal(error_code, error_message, error_details);
}

}  // namespace flutter_desktop_embedding

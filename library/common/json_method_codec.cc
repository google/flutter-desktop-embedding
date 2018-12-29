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
#include "library/include/flutter_desktop_embedding/json_method_codec.h"

#include "library/common/internal/json_message_codec.h"
#include "library/include/flutter_desktop_embedding/json_method_call.h"

namespace flutter_desktop_embedding {

namespace {
// Keys used in MethodCall encoding.
constexpr char kMessageMethodKey[] = "method";
constexpr char kMessageArgumentsKey[] = "args";
}  // namespace

// static
const JsonMethodCodec &JsonMethodCodec::GetInstance() {
  static JsonMethodCodec sInstance;
  return sInstance;
}

std::unique_ptr<MethodCall> JsonMethodCodec::DecodeMethodCallInternal(
    const uint8_t *message, const size_t message_size) const {
  std::unique_ptr<Json::Value> json_message =
      JsonMessageCodec::GetInstance().DecodeMessage(message, message_size);
  if (!json_message) {
    return nullptr;
  }

  Json::Value method = (*json_message)[kMessageMethodKey];
  if (method.isNull()) {
    return nullptr;
  }
  Json::Value arguments = (*json_message)[kMessageArgumentsKey];
  return std::make_unique<JsonMethodCall>(method.asString(), arguments);
}

std::unique_ptr<std::vector<uint8_t>> JsonMethodCodec::EncodeMethodCallInternal(
    const MethodCall &method_call) const {
  Json::Value message(Json::objectValue);
  message[kMessageMethodKey] = method_call.method_name();
  message[kMessageArgumentsKey] =
      *static_cast<const Json::Value *>(method_call.arguments());

  return JsonMessageCodec::GetInstance().EncodeMessage(message);
}

std::unique_ptr<std::vector<uint8_t>>
JsonMethodCodec::EncodeSuccessEnvelopeInternal(const void *result) const {
  Json::Value envelope(Json::arrayValue);
  envelope.append(result == nullptr
                      ? Json::Value()
                      : *static_cast<const Json::Value *>(result));
  return JsonMessageCodec::GetInstance().EncodeMessage(envelope);
}

std::unique_ptr<std::vector<uint8_t>>
JsonMethodCodec::EncodeErrorEnvelopeInternal(const std::string &error_code,
                                             const std::string &error_message,
                                             const void *error_details) const {
  Json::Value envelope(Json::arrayValue);
  envelope.append(error_code);
  envelope.append(error_message.empty() ? Json::Value() : error_message);
  envelope.append(error_details == nullptr
                      ? Json::Value()
                      : *static_cast<const Json::Value *>(error_details));
  return JsonMessageCodec::GetInstance().EncodeMessage(envelope);
}

}  // namespace flutter_desktop_embedding

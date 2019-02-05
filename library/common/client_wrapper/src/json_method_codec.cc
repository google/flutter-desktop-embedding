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
#include "flutter_desktop_embedding/json_method_codec.h"

#include "flutter_desktop_embedding/json_message_codec.h"

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

std::unique_ptr<MethodCall<Json::Value>>
JsonMethodCodec::DecodeMethodCallInternal(const uint8_t *message,
                                          const size_t message_size) const {
  std::unique_ptr<Json::Value> json_message =
      JsonMessageCodec::GetInstance().DecodeMessage(message, message_size);
  if (!json_message) {
    return nullptr;
  }

  Json::Value method = (*json_message)[kMessageMethodKey];
  if (method.isNull()) {
    return nullptr;
  }
  return std::make_unique<MethodCall<Json::Value>>(
      method.asString(),
      std::make_unique<Json::Value>((*json_message)[kMessageArgumentsKey]));
}

std::unique_ptr<std::vector<uint8_t>> JsonMethodCodec::EncodeMethodCallInternal(
    const MethodCall<Json::Value> &method_call) const {
  Json::Value message(Json::objectValue);
  message[kMessageMethodKey] = method_call.method_name();
  const Json::Value *arguments = method_call.arguments();
  message[kMessageArgumentsKey] = arguments ? *arguments : Json::Value();

  return JsonMessageCodec::GetInstance().EncodeMessage(message);
}

std::unique_ptr<std::vector<uint8_t>>
JsonMethodCodec::EncodeSuccessEnvelopeInternal(
    const Json::Value *result) const {
  Json::Value envelope(Json::arrayValue);
  envelope.append(result == nullptr ? Json::Value() : *result);
  return JsonMessageCodec::GetInstance().EncodeMessage(envelope);
}

std::unique_ptr<std::vector<uint8_t>>
JsonMethodCodec::EncodeErrorEnvelopeInternal(
    const std::string &error_code, const std::string &error_message,
    const Json::Value *error_details) const {
  Json::Value envelope(Json::arrayValue);
  envelope.append(error_code);
  envelope.append(error_message.empty() ? Json::Value() : error_message);
  envelope.append(error_details == nullptr ? Json::Value() : *error_details);
  return JsonMessageCodec::GetInstance().EncodeMessage(envelope);
}

}  // namespace flutter_desktop_embedding

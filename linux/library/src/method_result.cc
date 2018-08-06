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
#include "linux/library/include/flutter_desktop_embedding/method_result.h"

#include <iostream>

namespace flutter_desktop_embedding {

void MethodResult::Success(const Json::Value &result) {
  SuccessInternal(result);
}

void MethodResult::Error(const std::string &error_code,
                         const std::string &error_message,
                         const Json::Value &error_details) {
  ErrorInternal(error_code, error_message, error_details);
}

void MethodResult::NotImplemented() { NotImplementedInternal(); }

JsonMethodResult::JsonMethodResult(
    FlutterEngine engine,
    const FlutterPlatformMessageResponseHandle *response_handle)
    : engine_(engine), response_handle_(response_handle) {
  if (!response_handle_) {
    std::cerr << "Error: Response handle must be provided for a response."
              << std::endl;
  }
}

JsonMethodResult::~JsonMethodResult() {
  if (response_handle_) {
    // Warn, rather than send a not-implemented response, since the engine may
    // no longer be valid at this point.
    std::cerr
        << "Warning: Failed to respond to a message. This is a memory leak."
        << std::endl;
  }
}

void JsonMethodResult::SuccessInternal(const Json::Value &result) {
  Json::Value response(Json::arrayValue);
  response.append(result);
  SendResponseJson(response);
}

void JsonMethodResult::ErrorInternal(const std::string &error_code,
                                     const std::string &error_message,
                                     const Json::Value &error_details) {
  Json::Value response(Json::arrayValue);
  response.append(error_code);
  response.append(error_message.empty() ? Json::Value() : error_message);
  response.append(error_details);
  SendResponseJson(response);
}

void JsonMethodResult::NotImplementedInternal() { SendResponse(nullptr); }

void JsonMethodResult::SendResponseJson(const Json::Value &response) {
  Json::StreamWriterBuilder writer_builder;
  std::string response_data = Json::writeString(writer_builder, response);
  SendResponse(&response_data);
}

void JsonMethodResult::SendResponse(const std::string *serialized_response) {
  if (!response_handle_) {
    std::cerr
        << "Error: Response can be set only once. Ignoring duplicate response."
        << std::endl;
    return;
  }

  const uint8_t *message_data =
      serialized_response
          ? reinterpret_cast<const uint8_t *>(serialized_response->c_str())
          : nullptr;
  size_t message_length = serialized_response ? serialized_response->size() : 0;
  FlutterEngineSendPlatformMessageResponse(engine_, response_handle_,
                                           message_data, message_length);
  // The engine frees the response handle once
  // FlutterEngineSendPlatformMessageResponse is called.
  response_handle_ = nullptr;
}

}  // namespace flutter_desktop_embedding

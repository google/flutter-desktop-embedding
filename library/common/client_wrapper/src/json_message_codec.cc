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
#include "flutter_desktop_embedding/json_message_codec.h"

#include <iostream>
#include <string>

namespace flutter_desktop_embedding {

// static
const JsonMessageCodec &JsonMessageCodec::GetInstance() {
  static JsonMessageCodec sInstance;
  return sInstance;
}

std::unique_ptr<std::vector<uint8_t>> JsonMessageCodec::EncodeMessageInternal(
    const Json::Value &message) const {
  Json::StreamWriterBuilder writer_builder;
  std::string serialization = Json::writeString(writer_builder, message);

  return std::make_unique<std::vector<uint8_t>>(serialization.begin(),
                                                serialization.end());
}

std::unique_ptr<Json::Value> JsonMessageCodec::DecodeMessageInternal(
    const uint8_t *binary_message, const size_t message_size) const {
  Json::CharReaderBuilder reader_builder;
  std::unique_ptr<Json::CharReader> parser(reader_builder.newCharReader());

  auto raw_message = reinterpret_cast<const char *>(binary_message);
  auto json_message = std::make_unique<Json::Value>();
  std::string parse_errors;
  bool parsing_successful =
      parser->parse(raw_message, raw_message + message_size, json_message.get(),
                    &parse_errors);
  if (!parsing_successful) {
    std::cerr << "Unable to parse JSON message:" << std::endl
              << parse_errors << std::endl;
    return nullptr;
  }
  return json_message;
}

}  // namespace flutter_desktop_embedding

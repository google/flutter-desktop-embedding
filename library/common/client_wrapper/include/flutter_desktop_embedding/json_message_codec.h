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
#ifndef LIBRARY_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_JSON_MESSAGE_CODEC_H_
#define LIBRARY_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_JSON_MESSAGE_CODEC_H_

#include <json/json.h>

#include "message_codec.h"

namespace flutter_desktop_embedding {

// A message encoding/decoding mechanism for communications to/from the
// Flutter engine via JSON channels.
class JsonMessageCodec : public MessageCodec<Json::Value> {
 public:
  // Returns the shared instance of the codec.
  static const JsonMessageCodec &GetInstance();

  ~JsonMessageCodec() = default;

  // Prevent copying.
  JsonMessageCodec(JsonMessageCodec const &) = delete;
  JsonMessageCodec &operator=(JsonMessageCodec const &) = delete;

 protected:
  // Instances should be obtained via GetInstance.
  JsonMessageCodec() = default;

  // MessageCodec:
  std::unique_ptr<Json::Value> DecodeMessageInternal(
      const uint8_t *binary_message, const size_t message_size) const override;
  std::unique_ptr<std::vector<uint8_t>> EncodeMessageInternal(
      const Json::Value &message) const override;
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_JSON_MESSAGE_CODEC_H_

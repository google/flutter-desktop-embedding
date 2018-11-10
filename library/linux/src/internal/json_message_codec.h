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
#ifndef LIBRARY_LINUX_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_JSON_MESSAGE_CODEC_H_
#define LIBRARY_LINUX_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_JSON_MESSAGE_CODEC_H_

#include <memory>
#include <vector>

#include <json/json.h>

namespace flutter_desktop_embedding {

// A message encoding/decoding mechanism for communications to/from the
// Flutter engine via JSON channels.
//
// TODO: Make this public, once generalizing a MessageCodec parent interface is
// addressed; this is complicated by the return type of EncodeMessage.
// Part of issue #102.
class JsonMessageCodec {
 public:
  // Returns the shared instance of the codec.
  static const JsonMessageCodec &GetInstance();

  ~JsonMessageCodec() = default;

  // Prevent copying.
  JsonMessageCodec(JsonMessageCodec const &) = delete;
  JsonMessageCodec &operator=(JsonMessageCodec const &) = delete;

  // Returns a binary encoding of the given message, or nullptr if the
  // message cannot be serialized by this codec.
  std::unique_ptr<std::vector<uint8_t>> EncodeMessage(
      const Json::Value &message) const;

  // Returns the MethodCall encoded in |message|, or nullptr if it cannot be
  // decoded.
  // TODO: Consider adding absl as a dependency and using absl::Span.
  std::unique_ptr<Json::Value> DecodeMessage(const uint8_t *message,
                                             const size_t message_size) const;

 protected:
  // Instances should be obtained via GetInstance.
  JsonMessageCodec() = default;
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_LINUX_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_JSON_MESSAGE_CODEC_H_

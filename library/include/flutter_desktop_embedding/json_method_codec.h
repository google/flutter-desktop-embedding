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
#ifndef LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_JSON_METHOD_CODEC_H_
#define LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_JSON_METHOD_CODEC_H_

#include "method_codec.h"

namespace flutter_desktop_embedding {

// An implementation of MethodCodec that uses JSON strings as the serialization.
//
// void* types in this implementation must always be Json::Value* types (from
// the jsoncpp library).
class JsonMethodCodec : public MethodCodec {
 public:
  // Returns the shared instance of the codec.
  static const JsonMethodCodec &GetInstance();

  ~JsonMethodCodec() = default;

  // Prevent copying.
  JsonMethodCodec(JsonMethodCodec const &) = delete;
  JsonMethodCodec &operator=(JsonMethodCodec const &) = delete;

 protected:
  // Instances should be obtained via GetInstance.
  JsonMethodCodec() = default;

  // MethodCodec:
  std::unique_ptr<MethodCall> DecodeMethodCallInternal(
      const uint8_t *message, const size_t message_size) const override;
  std::unique_ptr<std::vector<uint8_t>> EncodeMethodCallInternal(
      const MethodCall &method_call) const override;
  std::unique_ptr<std::vector<uint8_t>> EncodeSuccessEnvelopeInternal(
      const void *result) const override;
  std::unique_ptr<std::vector<uint8_t>> EncodeErrorEnvelopeInternal(
      const std::string &error_code, const std::string &error_message,
      const void *error_details) const override;
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_JSON_METHOD_CODEC_H_

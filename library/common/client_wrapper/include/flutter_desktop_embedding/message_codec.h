// Copyright 2019 Google LLC
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
#ifndef LIBRARY_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_MESSAGE_CODEC_H_
#define LIBRARY_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_MESSAGE_CODEC_H_

#include <memory>
#include <string>
#include <vector>

namespace flutter_desktop_embedding {

// Translates between a binary message and higher-level method call and
// response/error objects.
template <typename T>
class MessageCodec {
 public:
  MessageCodec() = default;
  virtual ~MessageCodec() = default;

  // Prevent copying.
  MessageCodec(MessageCodec<T> const &) = delete;
  MessageCodec &operator=(MessageCodec<T> const &) = delete;

  // Returns the message encoded in |binary_message|, or nullptr if it cannot be
  // decoded by this codec.
  // TODO: Consider adding absl as a dependency and using absl::Span.
  std::unique_ptr<T> DecodeMessage(const uint8_t *binary_message,
                                   const size_t message_size) const {
    return std::move(DecodeMessageInternal(binary_message, message_size));
  }

  // Returns a binary encoding of the given |message|, or nullptr if the
  // message cannot be serialized by this codec.
  std::unique_ptr<std::vector<uint8_t>> EncodeMessage(const T &message) const {
    return std::move(EncodeMessageInternal(message));
  }

 protected:
  // Implementations of the public interface, to be provided by subclasses.
  virtual std::unique_ptr<T> DecodeMessageInternal(
      const uint8_t *binary_message, const size_t message_size) const = 0;
  virtual std::unique_ptr<std::vector<uint8_t>> EncodeMessageInternal(
      const T &message) const = 0;
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_MESSAGE_CODEC_H_

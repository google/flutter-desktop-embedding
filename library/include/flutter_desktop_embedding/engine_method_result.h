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
#ifndef LIBRARY_LINUX_SRC_INTERNAL_ENGINE_METHOD_RESULT_H_
#define LIBRARY_LINUX_SRC_INTERNAL_ENGINE_METHOD_RESULT_H_

#include <memory>
#include <string>
#include <vector>

#include "binary_messenger.h"
#include "method_codec.h"
#include "method_result.h"

namespace flutter_desktop_embedding {

namespace internal {
// Manages the one-time sending of response data. This is an internal helper
// class for EngineMethodResult, separated out since the implementation doesn't
// vary based on the template type.
class ReplyManager {
 public:
  ReplyManager(BinaryReply reply_handler_);
  ~ReplyManager();

  // Prevent copying.
  ReplyManager(ReplyManager const &) = delete;
  ReplyManager &operator=(ReplyManager const &) = delete;

  // Sends the given response data (which must either be nullptr, which
  // indicates an unhandled method, or a response serialized with |codec_|) to
  // the engine.
  void SendResponseData(const std::vector<uint8_t> *data);

 private:
  BinaryReply reply_handler_;
};
}  // namespace internal

// Implemention of MethodResult that sends a response to the Flutter engine
// exactly once, encoded using a given codec.
template <typename T>
class EngineMethodResult : public MethodResult<T> {
 public:
  // Creates a result object that will send results to |reply_handler|, encoded
  // using |codec|. The |codec| pointer must remain valid for as long as this
  // object exists.
  EngineMethodResult(BinaryReply reply_handler, const MethodCodec<T> *codec)
      : reply_manager_(
            std::make_unique<internal::ReplyManager>(std::move(reply_handler))),
        codec_(codec) {}
  ~EngineMethodResult() = default;

 protected:
  // MethodResult:
  void SuccessInternal(const T *result) override {
    std::unique_ptr<std::vector<uint8_t>> data =
        codec_->EncodeSuccessEnvelope(result);
    reply_manager_->SendResponseData(data.get());
  }
  void ErrorInternal(const std::string &error_code,
                     const std::string &error_message,
                     const T *error_details) override {
    std::unique_ptr<std::vector<uint8_t>> data =
        codec_->EncodeErrorEnvelope(error_code, error_message, error_details);
    reply_manager_->SendResponseData(data.get());
  }
  void NotImplementedInternal() override {
    reply_manager_->SendResponseData(nullptr);
  }

 private:
  std::unique_ptr<internal::ReplyManager> reply_manager_;

  const MethodCodec<T> *codec_;
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_LINUX_SRC_INTERNAL_ENGINE_METHOD_RESULT_H_

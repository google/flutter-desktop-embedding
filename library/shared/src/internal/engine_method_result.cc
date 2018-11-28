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
#include "library/shared/src/internal/engine_method_result.h"

#include <iostream>

namespace flutter_desktop_embedding {

EngineMethodResult::EngineMethodResult(BinaryReply reply_handler,
                                       const MethodCodec *codec)
    : reply_handler_(std::move(reply_handler)), codec_(codec) {
  if (!reply_handler_) {
    std::cerr << "Error: Reply handler must be provided for a response."
              << std::endl;
  }
}

EngineMethodResult::~EngineMethodResult() {
  if (reply_handler_) {
    // Warn, rather than send a not-implemented response, since the engine may
    // no longer be valid at this point.
    std::cerr
        << "Warning: Failed to respond to a message. This is a memory leak."
        << std::endl;
  }
}

void EngineMethodResult::SuccessInternal(const void *result) {
  std::unique_ptr<std::vector<uint8_t>> data =
      codec_->EncodeSuccessEnvelope(result);
  SendResponseData(data.get());
}

void EngineMethodResult::ErrorInternal(const std::string &error_code,
                                       const std::string &error_message,
                                       const void *error_details) {
  std::unique_ptr<std::vector<uint8_t>> data =
      codec_->EncodeErrorEnvelope(error_code, error_message, error_details);
  SendResponseData(data.get());
}

void EngineMethodResult::NotImplementedInternal() { SendResponseData(nullptr); }

void EngineMethodResult::SendResponseData(const std::vector<uint8_t> *data) {
  if (!reply_handler_) {
    std::cerr
        << "Error: Only one of Success, Error, or NotImplemented can be called,"
        << " and it can be called exactyl once. Ignoring duplicate result."
        << std::endl;
    return;
  }

  const uint8_t *message = data && !data->empty() ? data->data() : nullptr;
  size_t message_size = data ? data->size() : 0;
  reply_handler_(message, message_size);
  reply_handler_ = nullptr;
}

}  // namespace flutter_desktop_embedding
